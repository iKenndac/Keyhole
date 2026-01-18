import Foundation
import Observation

enum MediaAppState: Equatable, Hashable {
    case notRunning
    case runningWithDeniedAutomationAccess
    case runningWithPendingAutomationAccess
    case runningWithAutomationAccess

    var appIsRunning: Bool {
        switch self {
        case .notRunning: return false
        case .runningWithDeniedAutomationAccess: return true
        case .runningWithPendingAutomationAccess: return true
        case .runningWithAutomationAccess: return true
        }
    }
}

enum MediaAppCommandError: Error {
    case appNotRunning
    case automationPending
    case automationDenied
}

protocol MediaAppIntegration: AnyObject {

    static var bundleId: String { get }
    var bundleId: String { get }
    var appName: String { get }

    @ObservationTracked var appState: MediaAppState { get }
    func addStateObserver(_ observer: @escaping MediaAppStateChangedObserver) -> MediaAppStateObservationToken
    func removeStateObserver(_ token: MediaAppStateObservationToken)

    func launchApplication(askingForAutomationPermission: Bool) async throws(MediaAppCommandError)
    func playPause() throws(MediaAppCommandError)
    func skipBack() throws(MediaAppCommandError)
    func skipForward() throws(MediaAppCommandError)
}

typealias MediaAppStateChangedObserver = (_ app: MediaAppIntegration, _ state: MediaAppState) -> (Void)

// Auto-invalidating observation tokens.
class MediaAppStateObservationToken: Hashable {

    static func == (lhs: MediaAppStateObservationToken, rhs: MediaAppStateObservationToken) -> Bool {
        return lhs.internalToken == rhs.internalToken
    }

    init(observing app: any MediaAppIntegration) {
        self.app = app
        self.internalToken = UUID().uuidString
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(internalToken)
    }

    private var internalToken: String
    private(set) weak var app: (any MediaAppIntegration)?

    func invalidate() {
        app?.removeStateObserver(self)
        app = nil
    }

    deinit {
        invalidate()
    }
}

/// This protocol provides default implementations for app state observer logic. App integrations need to conform
/// to this protocol and provide storage for observers, and the rest is provided.
protocol AppStateObservationDefaultImplementations: MediaAppIntegration {

    /// Storage for rating observers.
    var appStateChangedObserverStorage: [MediaAppStateObservationToken: MediaAppStateChangedObserver] { get set }

    /// Trigger rating changed observers on the calling thread.
    ///
    /// - Parameter rating: The rating to pass in the observation triggers.
    func triggerStateChangedObservers(with state: MediaAppState)
}

extension AppStateObservationDefaultImplementations {

    func addStateObserver(_ observer: @escaping MediaAppStateChangedObserver) -> MediaAppStateObservationToken {
        let token = MediaAppStateObservationToken(observing: self)
        appStateChangedObserverStorage[token] = observer
        return token
    }

    func removeStateObserver(_ token: MediaAppStateObservationToken) {
        appStateChangedObserverStorage.removeValue(forKey: token)
    }

    func triggerStateChangedObservers(with state: MediaAppState) {
        let observers = appStateChangedObserverStorage.values
        for observer in observers {
            observer(self, state)
        }
    }
}
