import Foundation
import Observation
import ScriptingBridge

@MainActor @Observable class LongplayAppIntegration: ScriptableAppIntegration<LongplayApplication> {

    override class var bundleId: String { return "app.longplay.Longplay-Mac" }
    override class var appName: LocalizedStringResource { return .longplayAppName }

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
