import Foundation
import SwiftUI

extension TargetNotRunningAction {
    var localizedDisplayValue: LocalizedStringResource {
        switch self {
        case .swallowEvent: return .targetNotRunningSwallowEventTitle
        case .propagateEvent: return .targetNotRunningPropagateEventTitle
        case .launchTarget: return .targetNotRunningLaunchTargetTitle
        }
    }
}

extension MediaKeyController.MediaAppDetailsWithState: Identifiable {
    var id: Self { return self }
}

extension MediaKey {
    var systemImageName: String {
        switch self {
        case .playPause: return "playpause.fill"
        case .fastForward, .nextTrack: return "forward.fill"
        case .rewind, .previousTrack: return "backward.fill"
        }
    }
}
