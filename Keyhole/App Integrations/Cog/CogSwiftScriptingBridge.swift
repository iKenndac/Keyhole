import Foundation
import ScriptingBridge

// This is here to give Swift real symbols to link against.
extension SBApplication: CogApplication {}

// The Doppler application. Base classes can be found in ScriptingSwiftBridgeBase.swift.
// I just pulled out the API needed for this app.
@objc protocol CogApplication: SBApplicationProtocol {

   @objc optional func play() // Begin playback.
   @objc optional func pause() // Pause playback.
   @objc optional func stop() // Stop playback.
   @objc optional func previous() // Play previous track.
   @objc optional func next() // Play next track.

}
