import Foundation
import ScriptingBridge
import AppKit

class ScriptingBridgeSession<T: SBApplicationProtocol> {

    init(bundleId: String) {
        self.bundleId = bundleId
        setupObservations()
        updateSessionState()
    }

    deinit {
        let notificationCenter = NSWorkspace.shared.notificationCenter
        notificationCenter.removeObserver(targetLaunchObservation!)
        notificationCenter.removeObserver(targetQuitObservation!)
        notificationCenter.removeObserver(applicationBecameActiveObservation!)
    }

    // MARK: - Public API

    /// The bundle ID of the application this session references.
    let bundleId: String

    /// The state of a session.
    ///
    /// - notRunning: The target is not running.
    /// - runningWithDeniedScriptingAccess: The target application is running, but we don't have scripting access.
    /// - runningWithPendingScriptingAccess: The target application is running, and scripting access is pending (the user hasn't been asked yet).
    /// - runningWithScriptingAccess: The target application is running and we have scripting access to it.
    enum State: CustomStringConvertible {
        case notRunning
        case runningWithDeniedScriptingAccess
        case runningWithPendingScriptingAccess
        case runningWithScriptingAccess(application: T)

        func isSameCase(as other: State) -> Bool {
            switch (self, other) {
            case (.notRunning, .notRunning): return true
            case (.runningWithDeniedScriptingAccess, .runningWithDeniedScriptingAccess): return true
            case (.runningWithPendingScriptingAccess, .runningWithPendingScriptingAccess): return true
            case (.runningWithScriptingAccess, .runningWithScriptingAccess): return true
            default: return false
            }
        }

        var isRunningWithScriptingAccess: Bool {
            switch (self) {
            case .runningWithScriptingAccess: return true
            default: return false
            }
        }

        var description: String {
            switch self {
            case .notRunning: return "application not running"
            case .runningWithDeniedScriptingAccess: return "application running with denied scripting access"
            case .runningWithPendingScriptingAccess: return "application running with pending scripting access"
            case .runningWithScriptingAccess(let app): return "application running with scripting access: \(app)"
            }
        }
    }

    /// Returns the current state of the session. Will be updated automatically as the target application launches and quits.
    private(set) var sessionState: State = .notRunning

    typealias StateObserver = ((ScriptingBridgeSession, State) -> Void)
    typealias ObserverToken = String
    private var stateObservers = [ObserverToken: StateObserver]()

    /// Add an observer to be called on the main thread when the state of the session changes.
    ///
    /// - Parameter observer: The observer to add.
    /// - Returns: An observer token, to be used with `removeStateObserver(_:)`.
    func addStateObserver(_ observer: @escaping StateObserver) -> ObserverToken {
        let token = UUID().uuidString
        stateObservers[token] = observer
        return token
    }

    /// Remove an existing state observer.
    ///
    /// - Parameter token: The observer token.
    func removeStateObserver(_ token: ObserverToken) {
        stateObservers.removeValue(forKey: token)
    }

    /// Launches the target application in the background and prompts the user to allow scripting access if possible.
    ///
    /// This method may complete without a prompt being given to the user if the application already has been allowed
    /// scripting access, or has previously been denied scripting access. If the current session state is
    /// `.runningWithScriptingAccess`, this method will complete as such but nothing else will happen.
    ///
    /// - Parameter completionHandler: The completion handler to be called on the main queue when the operation succeeds or fails.
    func attemptToGainScriptingAccess(completionHandler: @escaping (State) -> Void) {

        guard !sessionState.isRunningWithScriptingAccess else {
            completionHandler(sessionState)
            return
        }

        let targetBundleId = bundleId

        DispatchQueue.global(qos: .userInteractive).async {
            // We don't directly use the result from launchAndCheckScriptingAccess() - we check and convert to a session state later.
            launchAndCheckScriptingAccess(for: targetBundleId, allowUserPrompt: true, completionHandler: { [weak self] _ in
                guard let self else { return }
                self.updateSessionState()
                completionHandler(self.sessionState)
            })
        }
    }

    // MARK: - Application Running State

    private var targetLaunchObservation: Any!
    private var targetQuitObservation: Any!
    private var applicationBecameActiveObservation: Any!

    private func setupObservations() {
        let bundleId = self.bundleId
        let notificationCenter = NSWorkspace.shared.notificationCenter
        let targetLaunchNotification = NSWorkspace.didLaunchApplicationNotification
        let targetQuitNotification = NSWorkspace.didTerminateApplicationNotification

        targetLaunchObservation = notificationCenter.addObserver(forName: targetLaunchNotification, object: nil, queue: .main) { [weak self] notification in
            if let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                application.bundleIdentifier == bundleId {
                self?.updateSessionState()
            }
        }

        targetQuitObservation = notificationCenter.addObserver(forName: targetQuitNotification, object: nil, queue: .main) { [weak self] notification in
            if let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                application.bundleIdentifier == bundleId {
                self?.updateSessionState()
            }
        }

        let becameActiveNotification = NSApplication.didBecomeActiveNotification

        // Since the user can go to System Preferences and deny/allow access at any time, we should refresh when the app becomes active.
        applicationBecameActiveObservation = NotificationCenter.default.addObserver(forName: becameActiveNotification, object: nil, queue: nil) { [weak self] _ in
            self?.updateSessionState()
        }
    }

    private func updateSessionState() {
        let oldState = sessionState
        defer { fireObservers(from: oldState, to: sessionState) }

        let applicationIsRunning = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).count > 0
        guard applicationIsRunning else {
            sessionState = .notRunning
            return
        }

        switch checkScriptingAccess(for: bundleId, allowUserPrompt: false) {
        case .checkFailed: sessionState = .notRunning
        case .pendingAuthorisation: sessionState = .runningWithPendingScriptingAccess
        case .denied: sessionState = .runningWithDeniedScriptingAccess
        case .available:
            // We don't want to replace an already-existing SBApplication instance.
            if !sessionState.isRunningWithScriptingAccess {
                guard let sbApp = SBApplication(bundleIdentifier: bundleId) as? T else {
                    sessionState = .runningWithDeniedScriptingAccess
                    break
                }
                sessionState = .runningWithScriptingAccess(application: sbApp)
            }
        }
    }

    private func fireObservers(from oldState: State, to newState: State) {
        guard !oldState.isSameCase(as: newState) else { return }
        for observer in stateObservers.values {
            observer(self, newState)
        }
    }

}
