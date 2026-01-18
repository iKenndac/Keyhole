import Foundation
import CoreServices
import CoreGraphics
import AppKit
import Combine

enum MediaKey {
    case playPause
    case fastForward
    case rewind
    case previousTrack
    case nextTrack
}

enum MediaKeyHandlingResult {
    /// The event will be propagated to the rest of the system.
    case propagateEvent
    /// The event will be consumed, and not continue to the rest of the system.
    case blockEventPropagation
}

/// Class for listening to media key presses.
final class MediaKeyWatcher {

    init() {}

    deinit {
        stop()
    }

    // MARK: - API

    enum State: Hashable, Equatable {
        case stopped
        case missingAccessibilityPermissions
        case running
    }

    @MainActor @Published private(set) var state: State = .stopped

    typealias KeyHandler = (_ watcher: MediaKeyWatcher, _ key: MediaKey, _ keyDown: Bool) -> MediaKeyHandlingResult

    @MainActor var keyHandler: KeyHandler?

    // MARK: - Session Management

    private var activeTap: CFMachPort? = nil
    private var activeSource: CFRunLoopSource? = nil

    enum WatchError: Error {
        case missingAccessibilityPermissions
    }

    func start() throws(WatchError) {
        // Declaring this function (or the class) @MainActor futzes with passing function pointers to
        // `CGEvent.tapCreate`, and I'm too lazy to work around it. Crash at runtime instead, like the olden days.
        assert(Thread.isMainThread)

        guard activeTap == nil else { return }

        let tap: CFMachPort? = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                                 place: .headInsertEventTap,
                                                 options: .defaultTap,
                                                 eventsOfInterest: CGEventMask(1 << NX_SYSDEFINED),
                                                 callback: eventTapCallBack,
                                                 userInfo: Unmanaged.passUnretained(self).toOpaque())
        guard let tap else {
            state = .missingAccessibilityPermissions
            throw .missingAccessibilityPermissions
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorSystemDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        activeTap = tap
        activeSource = source
        state = .running
    }

    func stop() {
        if let activeTap { CFMachPortInvalidate(activeTap) }
        if let activeSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), activeSource, .commonModes) }
        activeTap = nil
        activeSource = nil
        state = .stopped
    }

    // MARK: - Internal Event Handling

    @MainActor fileprivate func handleTapEvent(_ event: CGEvent, of type: CGEventType) -> MediaKeyHandlingResult {
        guard let tap = activeTap else { return .propagateEvent }

        if type == .tapDisabledByTimeout {
            CGEvent.tapEnable(tap: tap, enable: true)
            return .propagateEvent
        }

        if type == .tapDisabledByUserInput {
            // I *think*, this happens when the tap is disabled with `CGEvent.tapEnable()`.
            return .propagateEvent
        }

        // If nobody's listening to us, continuing further is useless.
        guard let keyHandler else { return .propagateEvent }

        // Filter out events we're not interested in. I have no idea why media key presses have a
        // subtype of "An NSWindow has changed screens", but here we are.
        guard type == CGEventType(rawValue: UInt32(NX_SYSDEFINED)),
              let nsEvent = NSEvent(cgEvent: event), nsEvent.subtype == .screenChanged else {
            return .propagateEvent
        }

        let rawKeyFlags: Int = (nsEvent.data1 & 0x0000ffff)
        let rawKeyCode: Int = (nsEvent.data1 & 0xffff0000) >> 16
        let keyDown: Bool = (((rawKeyFlags & 0xff00) >> 8) == 0xa)

        guard let keyCode = MediaKey(rawKeyCode: rawKeyCode) else {
            return .propagateEvent
        }

        return keyHandler(self, keyCode, keyDown)
    }
}

fileprivate func eventTapCallBack(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent,
                                  refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    autoreleasepool {
        assert(Thread.isMainThread)
        guard let pointerToTarget = refcon else { return .passUnretained(event) }
        let target = Unmanaged<MediaKeyWatcher>.fromOpaque(pointerToTarget).takeUnretainedValue()
        switch target.handleTapEvent(event, of: type) {
        case .propagateEvent: return .passUnretained(event)
        case .blockEventPropagation: return nil
        }
    }
}

fileprivate extension MediaKey {
    init?(rawKeyCode: Int) {
        // Swift doesn't allow us to assign runtime values to enum cases
        switch rawKeyCode {
        case Int(NX_KEYTYPE_PLAY): self = .playPause
        case Int(NX_KEYTYPE_FAST): self = .fastForward
        case Int(NX_KEYTYPE_REWIND): self = .rewind
        case Int(NX_KEYTYPE_PREVIOUS): self = .previousTrack
        case Int(NX_KEYTYPE_NEXT): self = .nextTrack
        default: return nil
        }
    }
}
