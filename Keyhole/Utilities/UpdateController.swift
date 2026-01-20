import Foundation
import Sparkle
import Observation
import AppKit

@Observable @MainActor class UpdateController: NSObject, SPUStandardUserDriverDelegate, SPUUpdaterDelegate {

    private var sparkle: SPUStandardUpdaterController!

    override init() {
        updateAvailable = false
        super.init()
        sparkle = SPUStandardUpdaterController(updaterDelegate: self, userDriverDelegate: self)
        automaticallyCheckForUpdates = sparkle.updater.automaticallyChecksForUpdates
    }
    
    /// Perform an explicit "Check for updates" action by the user. Will display dialogs.
    func checkForUpdates() {
        NSApplication.shared.activate()
        sparkle.checkForUpdates(nil)
    }
    
    /// Will be set to `true` if the automatic updater found and update.
    private(set) var updateAvailable: Bool
    
    /// Set to turn on or off automatic update checking.
    var automaticallyCheckForUpdates: Bool = false {
        didSet {
            sparkle.updater.automaticallyChecksForUpdates = automaticallyCheckForUpdates
            if !automaticallyCheckForUpdates { updateAvailable = false }
        }
    }

    // MARK: - Delegates

    var supportsGentleScheduledUpdateReminders: Bool {
        return true
    }

    func standardUserDriverShouldHandleShowingScheduledUpdate(_ update: SUAppcastItem,
                                                              andInImmediateFocus immediateFocus: Bool) -> Bool {
        // We should never pop up a dialog for a scheduled update check. The app will put a note in the UI.
        return false
    }

    func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem,
                                                   state: SPUUserUpdateState) {
        // We will ignore updates that the user driver will handle showing
        // This includes user initiated (non-scheduled) updates
        guard !handleShowingUpdate else { return }
        updateAvailable = true
    }

    func standardUserDriverWillFinishUpdateSession() {
        updateAvailable = false
    }
}
