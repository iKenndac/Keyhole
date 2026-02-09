import Foundation
import Observation
import ScriptingBridge

@MainActor @Observable class RadiccioAppIntegration: ScriptableAppIntegration<RadiccioApplication> {

    override class var bundleId: String { return "computer.crispycrunchy.radiccio" }
    override class var appName: String { return "Radiccio" }

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
