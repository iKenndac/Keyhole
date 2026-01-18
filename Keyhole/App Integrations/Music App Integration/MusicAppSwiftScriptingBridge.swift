import Foundation
import ScriptingBridge

// This is here to give Swift real symbols to link against.
extension SBApplication: MusicApplication {}

// The Music application. Base classes can be found in ScriptingSwiftBridgeBase.swift.
// I just pulled out the API needed for this app.
@objc protocol MusicApplication: SBApplicationProtocol {

    @objc optional var playerState: MusicPlayerState { get } // is the player stopped, paused, or playing?
    @objc optional var songRepeat: MusicRepeatState { get set } // the playback repeat mode
    // ^ I'm so annoyed by Music constantly turning off repeat on its own I might make a thing to force it back on.

    @objc optional func backTrack() // reposition to beginning of current track or go to previous track if already at start of current track
    @objc optional func fastForward() // skip forward in a playing track
    @objc optional func nextTrack() // advance to the next track in the current playlist
    @objc optional func pause() // pause playback
    @objc optional func playpause() // toggle the playing/paused state of the current track
    @objc optional func previousTrack() // return to the previous track in the current playlist
    @objc optional func resume() // disable fast forward/rewind and resume playback, if playing.
    @objc optional func rewind() // skip backwards in a playing track
    @objc optional func stop() // stop playback
}

@objc public enum /*MusicEPlS*/ MusicPlayerState: AEKeyword {
    case /*MusicEPlS*/ stopped = 0x6b505353 // 'kPSS'
    case /*MusicEPlS*/ playing = 0x6b505350 // 'kPSP'
    case /*MusicEPlS*/ paused = 0x6b505370 // 'kPSp'
    case /*MusicEPlS*/ fastForwarding = 0x6b505346 // 'kPSF'
    case /*MusicEPlS*/ rewinding = 0x6b505352 // 'kPSR'
}

@objc public enum /*MusicERpt*/ MusicRepeatState: AEKeyword {
    case /*MusicERptOff*/ repeatOff = 0x6b52704f // 'kRpO'
    case /*MusicERptOne*/ repeatOne = 0x6b527031 //'kRp1'
    case /*MusicERptAll*/ repeatAll = 0x6b416c6c // 'kAll'
}
