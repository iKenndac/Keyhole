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
        .init("TargetNotRunningAction", defaultValue: .propagateEvent)
    }
    static var mediaKeyListeningEnabled: UserDefaultsKey<Bool> {
        .init("MediaKeyHandlingEnabled", defaultValue: true)
    }
}

/// Central class for the app's core logic - taking media key presses and passing them along to a target application.
@Observable class MediaKeyController {

    private let keyWatcher: MediaKeyWatcher
    private let integrations: [any MediaAppIntegration]

    init() {
        // Only one for now, but literally the first ticket will be "But Spotify????", so might as well design for it.
        integrations = [MusicAppIntegration()]
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

    /// Returns `true` if the app has accessibility permissions, otherwise `false`.
    private(set) var hasAccessibilityPermission: Bool = false

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
        appStates = integrations.map({
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
        // Right now, only deal with key downs.
        guard isDown else { return .blockEventPropagation }

        print("I am handling a key!")

        guard let target = integrations.first(where: { $0.appState.appIsRunning }) else {
            switch targetNotRunningAction {
            case .swallowEvent: return .blockEventPropagation
            case .propagateEvent: return .propagateEvent
            case .launchTarget:
                // When we support multiple apps, we need to have a better target finding method.
                guard let target = integrations.first else { return .blockEventPropagation }
                attemptToGainPermissionToAutomate(target)
                return .blockEventPropagation
            }
        }

        if target.appState == .runningWithPendingAutomationAccess {
            attemptToGainPermissionToAutomate(target)
            return .blockEventPropagation
        }

        guard target.appState == .runningWithAutomationAccess else {
            return .blockEventPropagation
        }

        do {
            switch key {
            case .playPause: try target.playPause()
            case .previousTrack: try target.skipBack()
            case .nextTrack: try target.skipForward()
            case .fastForward: break
            case .rewind: break
            }
        } catch {
            // TODO: Log something.
        }

        return .blockEventPropagation
    }
}

