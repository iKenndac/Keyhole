import Foundation
import Observation
import ScriptingBridge

@MainActor @Observable class SpotifyAppIntegration: ScriptableAppIntegration<SpotifyApplication> {

    override class var bundleId: String { return "com.spotify.client" }
    override class var appName: String { return "Spotify" } // Localised?

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
