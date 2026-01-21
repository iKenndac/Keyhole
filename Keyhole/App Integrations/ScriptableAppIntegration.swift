import Foundation
import Observation
import ScriptingBridge
import AppKit

/// Base class for app integrations that use AppleScript/Scripting Bridge.
@MainActor @Observable class ScriptableAppIntegration<AppType: SBApplicationProtocol>: MediaAppIntegration, AppStateObservationDefaultImplementations {

    var appName: String { return Self.appName }
    var bundleId: String { return Self.bundleId }

    private let scriptableAppBridge: ScriptingBridgeSession<AppType>

    init() {
        isInstalled = (NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.bundleId) != nil)
        scriptableAppBridge = .init(bundleId: Self.bundleId)
        stateObserver = scriptableAppBridge.addStateObserver { [weak self] _, state in
            self?.updateAppState(with: state)
        }
        updateAppState(with: scriptableAppBridge.sessionState)
    }

    // MARK: - Overrides

    class var bundleId: String { fatalError("class var bundleId must be overridden!") }
    class var appName: String { fatalError("class var appName must be overridden!") }

    func playPause() throws(MediaAppCommandError) {
        fatalError("func playPause() must be overridden!")
    }

    func skipBack() throws(MediaAppCommandError) {
        fatalError("func skipBack() must be overridden!")
    }

    func skipForward() throws(MediaAppCommandError) {
        fatalError("func skipForward() must be overridden!")
    }

    // MARK: - API

    private(set) var isInstalled: Bool

    func launchApplication(askingForAutomationPermission askForPermission: Bool) async throws(MediaAppCommandError) {
        switch scriptableAppBridge.sessionState {
        case .notRunning: break
        case .runningWithScriptingAccess(_): return
        case .runningWithDeniedScriptingAccess: throw .automationDenied
        case .runningWithPendingScriptingAccess:
            if !askForPermission { throw .automationPending }
        }

        let result: Result<Void, MediaAppCommandError> = await withCheckedContinuation { continuation in
            scriptableAppBridge.attemptToGainScriptingAccess(completionHandler: { state in
                switch state {
                case .notRunning: continuation.resume(returning: .failure(.appNotRunning))
                case .runningWithDeniedScriptingAccess: continuation.resume(returning: .failure(.automationDenied))
                case .runningWithPendingScriptingAccess: continuation.resume(returning: .failure(.automationPending))
                case .runningWithScriptingAccess(_): continuation.resume(returning: .success(()))
                }
            })
        }

        switch result {
        case .success: updateAppState(with: scriptableAppBridge.sessionState)
        case .failure(let error): throw error
        }
    }

    // MARK: - Helpers

    func scriptableApp() throws(MediaAppCommandError) -> AppType {
        switch scriptableAppBridge.sessionState {
        case .notRunning: throw .appNotRunning
        case .runningWithDeniedScriptingAccess: throw .automationDenied
        case .runningWithPendingScriptingAccess: throw .automationPending
        case .runningWithScriptingAccess(let app): return app
        }
    }

    // MARK: - State Observation

    var appStateChangedObserverStorage: [MediaAppStateObservationToken: MediaAppStateChangedObserver] = [:]
    private var stateObserver: ScriptingBridgeSession<AppType>.ObserverToken? = nil

    private(set) var appState: MediaAppState = .notRunning {
        didSet { triggerStateChangedObservers(with: appState) }
    }

    private func updateAppState(with sessionState: ScriptingBridgeSession<AppType>.State) {
        switch sessionState {
        case .notRunning: appState = .notRunning
        case .runningWithDeniedScriptingAccess: appState = .runningWithDeniedAutomationAccess
        case .runningWithPendingScriptingAccess: appState = .runningWithPendingAutomationAccess
        case .runningWithScriptingAccess(_): appState = .runningWithAutomationAccess
        }
    }
}
