import Foundation
import ScriptingBridge

// This is here to give Swift real symbols to link against.
extension SBApplication: SpotifyApplication {}

// The Spotify application. Base classes can be found in ScriptingSwiftBridgeBase.swift.
// I just pulled out the API needed for this app.
@objc protocol SpotifyApplication: SBApplicationProtocol {

    @objc optional var playerState: SpotifyPlayerState { get } // Is Spotify stopped, paused, or playing?

    @objc optional func nextTrack() // Skip to the next track.
    @objc optional func previousTrack() // Skip to the previous track.
    @objc optional func playpause() // Toggle play/pause.
    @objc optional func pause() // Pause playback.
    @objc optional func play() // Resume playback.
}

@objc public enum /*SpotifyEPlS*/ SpotifyPlayerState: AEKeyword {
    case /*SpotifyEPlSStopped*/ stopped = 0x6b505353 // 'kPSS',
    case /*SpotifyEPlSPlaying*/ playing = 0x6b505350 // 'kPSP',
    case /*SpotifyEPlSPaused*/ paused = 0x6b505370 // 'kPSp'
}
