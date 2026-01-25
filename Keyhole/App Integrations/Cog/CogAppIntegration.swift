import Foundation
import Observation
import ScriptingBridge

@MainActor @Observable class CogAppIntegration: ScriptableAppIntegration<CogApplication> {

	override class var bundleId: String { return "org.cogx.cog" }
	override class var appName: String { return "Cog" }

	override func playPause() throws(MediaAppCommandError) {
        // Cog's "play" command is actually play/pause.
		try scriptableApp().play?()
	}
	
	override func skipBack() throws(MediaAppCommandError) {
		try scriptableApp().previous?()
	}
	
	override func skipForward() throws(MediaAppCommandError) {
		try scriptableApp().next?()
	}
}
