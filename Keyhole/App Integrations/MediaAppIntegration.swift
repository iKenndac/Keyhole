import Foundation
import Observation

enum MediaAppState {
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

    @ObservationTracked var appState: MediaAppState { get }

    func launchApplication(askingForAutomationPermission: Bool) async throws(MediaAppCommandError)
    func playPause() throws(MediaAppCommandError)
    func skipBack() throws(MediaAppCommandError)
    func skipForward() throws(MediaAppCommandError)
}
