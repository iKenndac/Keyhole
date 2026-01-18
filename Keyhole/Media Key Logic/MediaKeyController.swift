import Foundation
import Combine

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
}

/// Central class for the app's core logic - taking media key presses and passing them along to a target application.
@MainActor @Observable class MediaKeyController {

    private let keyWatcher: MediaKeyWatcher
    private let integrations: [any MediaAppIntegration]

    init() {
        // Only one for now, but literally the first ticket will be "But Spotify????", so might as well design for it.
        integrations = [MusicAppIntegration()]
        targetNotRunningAction = UserDefaults.standard.value(for: .targetNotRunningAction)
        keyWatcher = MediaKeyWatcher()
        keyWatcher.keyHandler = handleMediaKey
        try? keyWatcher.start()
    }

    var targetNotRunningAction: TargetNotRunningAction {
        didSet { UserDefaults.standard.setValue(targetNotRunningAction, for: .targetNotRunningAction) }
    }

    func showAutomationDeniedAlert() {
        // TODO: Mechanism for not showing it again for a bit.
    }

    // MARK: - Key Handling Logic

    private func attemptToGainPermissionToAutomate(_ app: any MediaAppIntegration) {
        Task { @MainActor in
            do { try await app.launchApplication(askingForAutomationPermission: true) }
            catch { showAutomationDeniedAlert() }
        }
    }

    private func handleMediaKey(from watcher: MediaKeyWatcher, key: MediaKey, isDown: Bool) -> MediaKeyHandlingResult {
        // Right now, only deal with key downs.
        guard isDown else { return .blockEventPropagation }

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
            showAutomationDeniedAlert()
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
            showAutomationDeniedAlert()
        }

        return .blockEventPropagation
    }
}

