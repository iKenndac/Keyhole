import Foundation
import ScriptingBridge

// This is here to give Swift real symbols to link against.
extension SBApplication: RadiccioApplication {}

// The Radiccio application. Base classes can be found in ScriptingSwiftBridgeBase.swift.
// I just pulled out the API needed for this app.
@objc protocol RadiccioApplication: SBApplicationProtocol {

    @objc optional var playerState: RadiccioPlayerState { get } // is the player stopped, paused, or playing?

    @objc optional func nextTrack() // Advance to the next track in the current playback queue
    @objc optional func previousTrack() // Return to the previous track in the current playback queue
    @objc optional func playpause() // Toggle the playing/paused state of the current track, or stop if it is a live stream
    @objc optional func pause() // Pause playback
    @objc optional func play() // Play the current track
    @objc optional func stop()  // Stop playback
    @objc optional func restartTrack()  // Reposition to beginning of current track
}

@objc public enum /*RadiccioRdPS*/ RadiccioPlayerState: AEKeyword {
    case /*RadiccioRdPSStopped*/ stopped = 0x72645354 // 'rdST',
    case /*RadiccioRdPSPlaying*/ playing = 0x7264504c // 'rdPL',
    case /*RadiccioRdPSPaused*/ paused = 0x72645041 // 'rdPA'
}
