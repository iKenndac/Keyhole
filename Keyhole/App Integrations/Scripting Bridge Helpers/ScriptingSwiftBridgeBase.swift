import Foundation
import ScriptingBridge
import AppKit

/// Automation status values.
///
/// - checkFailed: The automation check could not be carried out (perhaps the target application isn't installed?)
/// - pendingAuthorisation: The user has not yet approved or denied automation access to the target application.
/// - available: The target application is available to be automated.
/// - denied: The target application is not available to be automated (typically, because it's been denied by the user).
@objc enum ScriptingAccess: Int, CustomStringConvertible {
    case checkFailed
    case pendingAuthorisation
    case available
    case denied

    var description: String {
        switch self {
        case .checkFailed: return "checkFailed"
        case .pendingAuthorisation: return "pendingAuthorisation"
        case .available: return "available"
        case .denied: return "denied"
        }
    }
}

/// Launches the given application (if not already running) and checks if it has scripting access.
///
/// - Parameter bundleId: The bundle ID of the target application.
/// - Parameter allowUserPrompt: Allow prompting for scripting access to the target application.
/// - Parameter completionHandler: The completion handler, to be called on the main queue, with the result.
/// - Returns: Returns a `ScriptingAccess` value reflecting the automation status of the application.
func launchAndCheckScriptingAccess(for bundleId: String, allowUserPrompt: Bool,
                                   completionHandler: @escaping (ScriptingAccess) -> Void) {

    let workspace = NSWorkspace.shared
    let isAlreadyRunning = (workspace.runningApplications.first(where: { $0.bundleIdentifier == bundleId }) != nil)

    if isAlreadyRunning {
        // checkScriptingAccess() on the main thread is a bad time.
        DispatchQueue.global(qos: .userInitiated).async {
            let result = checkScriptingAccess(for: bundleId, allowUserPrompt: allowUserPrompt)
            DispatchQueue.main.async { completionHandler(result) }
        }
        return
    }

    guard let url = workspace.urlForApplication(withBundleIdentifier: bundleId) else {
        DispatchQueue.main.async { completionHandler(.checkFailed) }
        return
    }

    let config = NSWorkspace.OpenConfiguration()
    config.activates = false
    config.hides = true
    config.allowsRunningApplicationSubstitution = true
    config.createsNewApplicationInstance = false
    config.promptsUserIfNeeded = allowUserPrompt

    workspace.openApplication(at: url, configuration: config, completionHandler: { app, error in
        if app != nil {
            // checkScriptingAccess() on the main thread is a bad time.
            DispatchQueue.global(qos: .userInitiated).async {
                let state = checkScriptingAccess(for: bundleId, allowUserPrompt: allowUserPrompt)
                DispatchQueue.main.async { completionHandler(state) }
            }
        } else {
            DispatchQueue.main.async { completionHandler(.checkFailed) }
        }
    })
}

/// Checks the scripting access the running application has to the target application.
///
/// - Parameter bundleId: The bundle ID of the target application.
/// - Parameter allowUserPrompt: Allow prompting for scripting access to the target application.
/// - Returns: Returns a `ScriptingAccess` value reflecting the automation status of the application, including `.checkFailed` if the application isn't running.
func checkScriptingAccess(for bundleId: String, allowUserPrompt: Bool) -> ScriptingAccess {

    guard #available(OSX 10.14, *) else {
        // Earlier OS versions don't have access control over Apple Events.
        return .available
    }

    if allowUserPrompt {
        // From the docs: Do not call this function on your main thread because it may take arbitrarily long
        // to return if the user needs to be prompted for consent.
        assert(!Thread.isMainThread)
    }

    guard let desc = NSAppleEventDescriptor(bundleIdentifier: bundleId).aeDesc else { return .checkFailed }
    let result: OSStatus = AEDeterminePermissionToAutomateTarget(desc, typeWildCard, typeWildCard, allowUserPrompt)
    switch result {
    case Int32(errAEEventNotPermitted):
        // Can happen if you don't have an NSAppleEventsUsageDescription key/value in the Info.plist.
        return .denied
    case Int32(errAEEventWouldRequireUserConsent):
        return .pendingAuthorisation
    case noErr:
        return .available
    default:
        // Note to future self: If you get here and are confused, make sure you've added the target bundle identifier
        // to the com.apple.security.temporary-exception.apple-events entry in the entitlements file.
        return .checkFailed
    }
}

// This is here because the Scripting Bridge is not directly available to Swift due to
// linker requirements (the Scripting Bridge creates virtual classes).

@objc protocol SBObjectProtocol: NSObjectProtocol {

    /// Evaluates the object immediately, throwing an error if it's invalid.
    ///
    /// - Returns: The valid object, or nil if evaluation failed.
    func get() -> Any?
}

@objc protocol SBApplicationProtocol: SBObjectProtocol {

    /// Bring the application to the front.
    func activate()

    /// Returns `true` if the application is running.
    var isRunning: Bool { get }

    /// Sets the application's delegate.
    var delegate: SBApplicationDelegate? { get set }

    /// Returns the class for creating new scripting objects.
    ///
    /// - Parameter className: The scripting class name.
    /// - Returns: Returns the class for creating an object of the given scripting class.
    func `class`(forScriptingClass className: String) -> AnyClass?
}
