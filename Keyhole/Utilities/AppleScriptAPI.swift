import Foundation
import AppKit

/// This is where our AppleScript API is actually handled. Requests come in either via `NSApplication.value(forKey:)`
/// or our `NSScriptCommand` subclasses.
class KeyholeAppleScriptAPI {

    enum Property: String {
        case preferredApp = "preferredApp"
    }

    enum Command {
        case playPause
        case nextTrack
        case backTrack
    }

    init() {
        // We need AppKit to use our NSApplication subclass, so it's important we call this very early in the app's
        // lifecycle. This means that our setup is a bit awkward, since we need to be given dependencies later.
        let app = (ScriptableApplication.shared as? ScriptableApplication)
        KeyholeScriptCommand.registerHelper(self)
        app?.scriptingPropertyValueProvider = { [weak self] property in
            return self?.scriptingValue(for: property)
        }
    }

    private(set) weak var mediaKeyController: MediaKeyController?

    func setup(with keyController: MediaKeyController) {
        mediaKeyController = keyController
    }

    func scriptingValue(for property: Property) -> Any? {
        switch property {
        case .preferredApp: return mediaKeyController?.preferredTarget.bundleId
        }
    }

    func executeCommand(_ command: Command) {
        switch command {
        case .playPause: mediaKeyController?.simulatePressAndRelease(of: .playPause)
        case .nextTrack: mediaKeyController?.simulatePressAndRelease(of: .nextTrack)
        case .backTrack: mediaKeyController?.simulatePressAndRelease(of: .previousTrack)
        }
    }
}

// MARK: - AppleScript Entrypoints

// Properties on the AppleScript application come in value `valueForKey:` on `NSApplication`. We declare a subclass
// here (and make sure it's registered very early in the app's lifecycle).
@objc(ScriptableApplication) class ScriptableApplication: NSApplication {

    // Rather than handle property-getting logic for AppleScript here, we'll figure out if we're being
    // asked for a property from our AppleScript API, and hand off to our core logic class.
    var scriptingPropertyValueProvider: ((KeyholeAppleScriptAPI.Property) -> Any?)? = nil

    override func value(forKey key: String) -> Any? {
        guard let knownScriptingKey = KeyholeAppleScriptAPI.Property(rawValue: key) else {
            return super.value(forKey: key)
        }

        guard let scriptingPropertyValueProvider else {
            LogError("WARNING: Received request for scripting property value for \(key), but we don't have a handler!")
            return nil
        }

       return scriptingPropertyValueProvider(knownScriptingKey)
    }
}

/// Handler for the `playpause` script command.
@objc(PlayPauseScriptingAction) class PlayPauseScriptingAction: KeyholeScriptCommand {
    override func performCommand() throws(NSError) -> Any? {
        scriptingHelper.executeCommand(.playPause)
        return nil
    }
}

/// Handler for the `next track` script command.
@objc(NextTrackScriptingAction) class NextTrackScriptingAction: KeyholeScriptCommand {
    override func performCommand() throws(NSError) -> Any? {
        scriptingHelper.executeCommand(.nextTrack)
        return nil
    }
}

/// Handler for the `back track` script command.
@objc(BackTrackScriptingAction) class BackTrackScriptingAction: KeyholeScriptCommand {
    override func performCommand() throws(NSError) -> Any? {
        scriptingHelper.executeCommand(.backTrack)
        return nil
    }
}

// MARK: - Helper Types & Extensions

extension NSError {
    static var appleScriptInvalidParameter = NSError(domain: "org.danielkennett.Keyhole", code: NSArgumentsWrongScriptError)
}

extension NSScriptCommand {
    /// Populate the command with the given error. This will cause the receiver to fail.
    func populateWithError(_ error: NSError) {
        scriptErrorNumber = error.code
        scriptErrorString = error.localizedDescription
    }
}

/// Convenience subclass of `NSScriptCommand` that provides some useful features and a bridge to our
/// AppleScript-handling object.
class KeyholeScriptCommand: NSScriptCommand {

    private static weak var scriptingHelper: KeyholeAppleScriptAPI? = nil

    static func registerHelper(_ helper: KeyholeAppleScriptAPI) {
        scriptingHelper = helper
    }

    var scriptingHelper: KeyholeAppleScriptAPI {
        guard let helper = KeyholeScriptCommand.scriptingHelper else {
            fatalError("Scripting helper was not registered or was deallocated. Either way, this is a programmer error.")
        }
        return helper
    }

    /// Attempt to get scripting command parameter with the given name.
    func parameter<T>(for key: AppleScriptParameter<T>) throws(NSError) -> T {
        guard let value = evaluatedArguments?[key.key] else { return key.defaultValue }
        guard let typedValue = value as? T else { throw .appleScriptInvalidParameter }
        return typedValue
    }

    /// Attempt to get command's direct parameter.
    func directParameter<T>() throws(NSError) -> T {
        guard let value = directParameter as? T else { throw .appleScriptInvalidParameter }
        return value
    }

    /// Attempt to get command's direct parameter.
    func directParameter<T>() throws(NSError) -> T where T: RawRepresentable {
        guard let rawValue = directParameter as? T.RawValue else { throw .appleScriptInvalidParameter }
        guard let value = T(rawValue: rawValue) else { throw .appleScriptInvalidParameter }
        return value
    }

    @objc public override func performDefaultImplementation() -> Any? {
        // This default implementation performs some logic that all commands will need to do, defers the command
        // execution to a nicer method to override, and handles errors thrown by the executor.
        do {
            return try performCommand()
        } catch {
            populateWithError(error)
            return nil
        }
    }

    /// Perform the command. This must be overridden.
    func performCommand() throws(NSError) -> Any? {
        throw NSError(domain: "org.danielkennett.Keyhole", code: NSUnknownKeyScriptError, userInfo: nil)
    }
}

struct AppleScriptParameter<T> {
    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }

    let key: String
    let defaultValue: T
}
