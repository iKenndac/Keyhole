import Foundation
import AppKit
import ApplicationServices
import ServiceManagement

enum TargetNotRunningAction: String, CaseIterable, Equatable, Hashable, Identifiable {
    case swallowEvent
    case propagateEvent
    case launchTarget

    var id: Self { return self }
}

extension TargetNotRunningAction: UserDefaultsStoreableValue {
    static func fromDefaultsStoredValue(_ value: Any) -> TargetNotRunningAction? {
        guard let stringValue = value as? String else { return nil }
        return TargetNotRunningAction(rawValue: stringValue)
    }
    
    var defaultsStoreableValue: Any {
        return rawValue
    }
}

extension UserDefaultsKey {
    static var targetNotRunningAction: UserDefaultsKey<TargetNotRunningAction> {
        return .init("TargetNotRunningAction", defaultValue: .propagateEvent)
    }
    static var mediaKeyListeningEnabled: UserDefaultsKey<Bool> {
        return .init("MediaKeyHandlingEnabled", defaultValue: true)
    }
    static var preferredTargetBundleId: UserDefaultsKey<String> {
        return .init("PreferredTarget", defaultValue: MusicAppIntegration.bundleId, shouldRegister: false)
    }
}

/// Central class for the app's core logic - taking media key presses and passing them along to a target application.
@Observable class MediaKeyController {

    private let keyWatcher: MediaKeyWatcher
    let integrations: [any MediaAppIntegration]

    init() {
        integrations = [MusicAppIntegration(), SpotifyAppIntegration(), DopplerAppIntegration()]

        let preferredBundleId = UserDefaults.standard.value(for: .preferredTargetBundleId)
        let targets = integrations.filter({ $0.isInstalled }).map({ AvailableTarget(appName: $0.appName, bundleId: $0.bundleId) })
        availableTargets = targets
        preferredTarget = targets.first(where: { $0.bundleId == preferredBundleId }) ?? targets.first ??
            .init(appName: MusicAppIntegration.appName, bundleId: MusicAppIntegration.bundleId)

        targetNotRunningAction = UserDefaults.standard.value(for: .targetNotRunningAction)
        enabled = UserDefaults.standard.value(for: .mediaKeyListeningEnabled)
        keyWatcher = MediaKeyWatcher()
        keyWatcher.keyHandler = handleMediaKey
        updateAccessibilityState()
        setupObservations()
        updateAppStates()
        updateWillLaunchAtLogin()
        startKeyHandlingIfEnabled()
    }

    deinit {
        if let appBecameActiveToken { NotificationCenter.default.removeObserver(appBecameActiveToken) }
    }

    /// What should happen if a media key is pressed and the target app isn't running?
    var targetNotRunningAction: TargetNotRunningAction {
        didSet { UserDefaults.standard.setValue(targetNotRunningAction, for: .targetNotRunningAction) }
    }

    /// Set to `true` to enable media key listening, or `false` to stop it.
    var enabled: Bool {
        didSet {
            UserDefaults.standard.setValue(enabled, for: .mediaKeyListeningEnabled)
            if enabled { startKeyHandlingIfEnabled() }
            else { keyWatcher.stop() }
        }
    }
    
    /// The currently pressed key, if any.
    var currentlyPressedKey: MediaKey?

    /// Returns `true` if the app has accessibility permissions, otherwise `false`.
    private(set) var hasAccessibilityPermission: Bool = false

    struct AvailableTarget: Equatable, Hashable, Identifiable {
        var id: String { return bundleId }
        let appName: String
        let bundleId: String
    }
    
    /// Returns the list of available apps.
    private(set) var availableTargets: [AvailableTarget]
    
    /// Returns the preferred media key target. Will be adjusted if an app isn't installed on launch.
    var preferredTarget: AvailableTarget {
        didSet { UserDefaults.standard.setValue(preferredTarget.bundleId, for: .preferredTargetBundleId) }
    }

    struct MediaAppDetailsWithState: Equatable, Hashable {
        let bundleId: String
        let appName: String
        let state: MediaAppState
    }

    /// Returns the current automation states for the supported app integrations.
    private(set) var appStates: [MediaAppDetailsWithState] = []
    
    /// Returns `true` if there's a permissions problem somewhere. Useful for a general "!!!" alert.
    private(set) var hasPermissionsProblem: Bool = false

    // MARK: - Autolaunch

    /// Set to `true` to have the app open automatically at loging, or `false` to remove it from the list.
    /// Will auto-update if the user removes it in System Settings.
    var launchAtLogin: Bool = false {
        didSet {
            guard !_launchAtLoginRecursionGuard else { return }
            do {
                if launchAtLogin { try SMAppService.mainApp.register() }
                else { try SMAppService.mainApp.unregister() }
            } catch { }
            updateWillLaunchAtLogin()
        }
    }

    private var _launchAtLoginRecursionGuard: Bool = false
    private func updateWillLaunchAtLogin() {
        _launchAtLoginRecursionGuard = true
        launchAtLogin = (SMAppService.mainApp.status == .enabled)
        _launchAtLoginRecursionGuard = false
    }

    // MARK: - Permission & State Observing

    private var appBecameActiveToken: Any? = nil
    private var appStateTokens: [MediaAppStateObservationToken] = []

    private func setupObservations() {
        let becameActiveNotification = NSApplication.didBecomeActiveNotification
        let center = NotificationCenter.default
        appBecameActiveToken = center.addObserver(forName: becameActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.updateAccessibilityState()
            self?.updateWillLaunchAtLogin()
        }

        // The Observation framework makes it very hard to continuously observe things manually :/
        appStateTokens = integrations.map({ $0.addStateObserver({ [weak self] _, _ in self?.updateAppStates() }) })
    }

    func noteUIShown() {
        updateAccessibilityState()
        updateWillLaunchAtLogin()
    }

    private func updateAccessibilityState() {
        hasAccessibilityPermission = AXIsProcessTrusted()
        updateHasPermissionsProblemFromCachedProperties()
        startKeyHandlingIfEnabled()
    }

    private func updateAppStates() {
        appStates = integrations.filter({ $0.isInstalled }).map({
            MediaAppDetailsWithState(bundleId: $0.bundleId, appName: $0.appName, state: $0.appState)
        })
        updateHasPermissionsProblemFromCachedProperties()
    }

    private func updateHasPermissionsProblemFromCachedProperties() {
        let hasProblematicApp: Bool = integrations.contains(where: { $0.appState == .runningWithDeniedAutomationAccess })
        hasPermissionsProblem = (!hasAccessibilityPermission || hasProblematicApp)
    }

    // MARK: - Key Handling Logic

    private func startKeyHandlingIfEnabled() {
        guard enabled else { return }
        do { try keyWatcher.start() }
        catch { NSLog("Unable to start key handler with error: \(error)") }
    }

    private func attemptToGainPermissionToAutomate(_ app: any MediaAppIntegration) {
        Task { @MainActor in
            do { try await app.launchApplication(askingForAutomationPermission: true) }
            catch { }
        }
    }

    private func handleMediaKey(from watcher: MediaKeyWatcher, key: MediaKey, isDown: Bool) -> MediaKeyHandlingResult {
        currentlyPressedKey = (isDown ? key : nil)

        guard let target: any MediaAppIntegration = {
            let installedIntegrations = integrations.filter({ $0.isInstalled })
            // Prefer the picked target.
            if let pickedTarget = installedIntegrations.first(where: { $0.bundleId == preferredTarget.bundleId }) {
                return pickedTarget

            } else if let runningApp = installedIntegrations.first(where: { $0.appState.appIsRunning }) {
                return runningApp

            } else {
                return integrations.first
            }
        }() else { return .propagateEvent }

        // Right now, only deal with key downs.
        guard isDown else { return .blockEventPropagation }

        LogVerbose("Targeting \(key) towards \(target.bundleId)…")

        switch target.appState {
        case .notRunning:
            switch targetNotRunningAction {
            case .swallowEvent:
                LogVerbose("…it's not running, and we're swallowing the keypress as per the user setting.")
                return .blockEventPropagation
            case .propagateEvent:
                LogVerbose("…it's not running, and we're propagating the keypress to the system as per the user setting.")
                return .propagateEvent
            case .launchTarget:
                LogVerbose("…it's not running, and we're launching the target as per the user setting.")
                attemptToGainPermissionToAutomate(target)
                return .blockEventPropagation
            }

        case .runningWithDeniedAutomationAccess:
            // If we definitively don't have permission, the app will be showing a /!\ symbol in the menu bar.
            // TODO: Figure out if we should defer back to the system in this case, othewise we're breaking the media keys.
            LogWarning("\(target.bundleId) is running, but we don't have permission to automate it!")
            return .blockEventPropagation

        case .runningWithPendingAutomationAccess:
            LogVerbose("…it's running, but we don't have permission to automate *yet*. Let's ask!")
            attemptToGainPermissionToAutomate(target)
            return .blockEventPropagation

        case .runningWithAutomationAccess:
            do {
                switch key {
                case .playPause: try target.playPause()
                case .previousTrack: try target.skipBack()
                case .nextTrack: try target.skipForward()
                case .fastForward: break
                case .rewind: break
                }
                LogVerbose("…command sent to running process successfully.")
            } catch {
                LogWarning("Sending command to \(target.bundleId) failed with error: \(error)")
            }

            return .blockEventPropagation
        }
    }
}

