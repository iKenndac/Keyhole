import Foundation
import Observation

@MainActor @Observable class MusicAppIntegration: MediaAppIntegration {

    private let bundleId: String = "com.apple.Music"
    private let musicBridge: ScriptingBridgeSession<MusicApplication>

    init() {
        musicBridge = .init(bundleId: bundleId)
        stateObserver = musicBridge.addStateObserver { [weak self] _, state in
            self?.updateAppState(with: state)
        }
        updateAppState(with: musicBridge.sessionState)
    }

    // MARK: - API

    func launchApplication(askingForAutomationPermission askForPermission: Bool) async throws(MediaAppCommandError) {
        switch musicBridge.sessionState {
        case .notRunning: break
        case .runningWithScriptingAccess(_): return
        case .runningWithDeniedScriptingAccess: throw .automationDenied
        case .runningWithPendingScriptingAccess:
            if !askForPermission { throw .automationPending }
        }

        let result: Result<Void, MediaAppCommandError> = await withCheckedContinuation { continuation in
            musicBridge.attemptToGainScriptingAccess(completionHandler: { state in
                switch state {
                case .notRunning: continuation.resume(returning: .failure(.appNotRunning))
                case .runningWithDeniedScriptingAccess: continuation.resume(returning: .failure(.automationDenied))
                case .runningWithPendingScriptingAccess: continuation.resume(returning: .failure(.automationPending))
                case .runningWithScriptingAccess(_): continuation.resume(returning: .success(()))
                }
            })
        }

        switch result {
        case .success: updateAppState(with: musicBridge.sessionState)
        case .failure(let error): throw error
        }
    }

    func playPause() throws(MediaAppCommandError) {
        try scriptableApp().playpause?()
    }

    func skipBack() throws(MediaAppCommandError) {
        try scriptableApp().backTrack?()
    }

    func skipForward() throws(MediaAppCommandError) {
        try scriptableApp().nextTrack?()
    }

    // MARK: - Helpers

    func scriptableApp() throws(MediaAppCommandError) -> MusicApplication {
        switch musicBridge.sessionState {
        case .notRunning: throw .appNotRunning
        case .runningWithDeniedScriptingAccess: throw .automationDenied
        case .runningWithPendingScriptingAccess: throw .automationPending
        case .runningWithScriptingAccess(let app): return app
        }
    }

    // MARK: - State Observation

    private var stateObserver: ScriptingBridgeSession<MusicApplication>.ObserverToken? = nil
    private(set) var appState: MediaAppState = .notRunning

    private func updateAppState(with sessionState: ScriptingBridgeSession<MusicApplication>.State) {
        switch sessionState {
        case .notRunning: appState = .notRunning
        case .runningWithDeniedScriptingAccess: appState = .runningWithDeniedAutomationAccess
        case .runningWithPendingScriptingAccess: appState = .runningWithPendingAutomationAccess
        case .runningWithScriptingAccess(_): appState = .runningWithAutomationAccess
        }
    }
}
