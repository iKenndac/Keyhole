import Foundation
import Observation

@MainActor @Observable class MusicAppIntegration: ScriptableAppIntegration<MusicApplication> {

    override class var bundleId: String { return "com.apple.Music" }
    override class var appName: String { return "Music" } // Localised?

    override func playPause() throws(MediaAppCommandError) {
        try scriptableApp().playpause?()
    }

    override func skipBack() throws(MediaAppCommandError) {
        try scriptableApp().backTrack?()
    }

    override func skipForward() throws(MediaAppCommandError) {
        try scriptableApp().nextTrack?()
    }
}
