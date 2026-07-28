import Foundation
import ScriptingBridge

// This is here to give Swift real symbols to link against.
extension SBApplication: LongplayApplication {}

// The Longplay application. Base classes can be found in ScriptingSwiftBridgeBase.swift.
// I just pulled out the API needed for this app.
@objc protocol LongplayApplication: SBApplicationProtocol {

    @objc optional func nextTrack() // advance to the next track in the current album/playlist, or start the next album if this is the last track
    @objc optional func previousTrack() // return to the previous track in the current album/playlist
    @objc optional func playpause() // toggle the playing/paused state of the current album/playlist
    @objc optional func pause() // pauses the current album/playlist
    @objc optional func play() // play the current album/playlist or the specified one
    @objc optional func stop()  // stop playback
}
