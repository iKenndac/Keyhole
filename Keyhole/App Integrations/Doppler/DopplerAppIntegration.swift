import Foundation
import Observation
import ScriptingBridge

@MainActor @Observable class DopplerAppIntegration: ScriptableAppIntegration<DopplerApplication> {
	
	override class var bundleId: String { return "co.brushedtype.doppler-macos" }
	override class var appName: String { return "Doppler" }
	
	override func playPause() throws(MediaAppCommandError) {
		try scriptableApp().playpause?()
	}
	
	override func skipBack() throws(MediaAppCommandError) {
		try scriptableApp().previousTrack?()
	}
	
	override func skipForward() throws(MediaAppCommandError) {
		try scriptableApp().nextTrack?()
	}
}
