import Foundation
import ScriptingBridge

// This is here to give Swift real symbols to link against.
extension SBApplication: DopplerApplication {}

// The Doppler application. Base classes can be found in ScriptingSwiftBridgeBase.swift.
// I just pulled out the API needed for this app.
@objc protocol DopplerApplication: SBApplicationProtocol {
	
	@objc optional var playerState: DopplerPlayerState { get } // Is Doppler stopped, paused, or playing?
	
	@objc optional func nextTrack() // Skip to the next track.
	@objc optional func previousTrack() // Skip to the previous track.
	@objc optional func playpause() // Toggle play/pause.
	@objc optional func pause() // Pause playback.
	@objc optional func play() // Resume playback.
}

@objc public enum /*DopplerEPlS*/ DopplerPlayerState: AEKeyword {
	case /*DopplerEPlSStopped*/ stopped = 0x6b505353 // 'kPSS',
	case /*DopplerEPlSPlaying*/ playing = 0x6b505350 // 'kPSP',
	case /*DopplerEPlSPaused*/ paused = 0x6b505370 // 'kPSp'
}
