import SwiftUI

@main
struct KeyholeApp: App {

    struct WindowId {
        static let about = "about"
        static let permissionDoctor = "permission-doctor"
    }

    let mediaKeyController: MediaKeyController
    let updateController: UpdateController
    let appleScriptAPI: KeyholeAppleScriptAPI
    @Environment(\.openWindow) var openWindow

    init() {
        appleScriptAPI = KeyholeAppleScriptAPI()
        mediaKeyController = MediaKeyController()
        updateController = UpdateController()
        // The AppleScript API object needs to be set up before anything else, so dependencies get given later.
        appleScriptAPI.setup(with: mediaKeyController)
    }

    var autoShowPermissionDoctor: Bool {
        return !UserDefaults.standard.value(for: .hasCompletedOnboarding)
    }

    var menuBarImageName: String {
        // TODO: It'd be nice to have some custom icons here.
        if updateController.updateAvailable {
            return "arrow.up.circle.fill"
        } else if mediaKeyController.enabled {
            if mediaKeyController.hasPermissionsProblem {
                return "exclamationmark.triangle.fill"
            } else {
                return "play.fill"
            }
        } else {
            return "play.slash.fill"
        }
    }

    var body: some Scene {
        MenuBarExtra(.appName, systemImage: menuBarImageName) {
            SettingsView(mediaKeyController: mediaKeyController, updateController: updateController)
                .frame(maxHeight: .infinity)
                .containerBackground(.regularMaterial, for: .window)
        }
        .menuBarExtraStyle(.window)
        .defaultLaunchBehavior(.presented)
        .restorationBehavior(.disabled)
        .commands {
            CommandGroup(replacing: .appInfo) {
                // Probably unneeded since we're an agent, but oh well.
                Button { openWindow(id: WindowId.about) } label: { Text(.aboutMenuItemTitle) }
            }
        }

        Window(.aboutWindowTitle, id: WindowId.about) {
            AboutView()
                .toolbar(removing: .title)
                .toolbarBackground(.hidden, for: .windowToolbar)
                .containerBackground(.regularMaterial, for: .window)
                .windowMinimizeBehavior(.disabled)
                .windowFullScreenBehavior(.disabled)
        }
        .defaultLaunchBehavior(.suppressed)
        .windowBackgroundDragBehavior(.enabled)
        .windowResizability(.contentSize)
        .restorationBehavior(.disabled)
        .windowManagerRole(.associated)
        .windowLevel(.floating)

        Window(.permissionDoctorWindowTitle, id: WindowId.permissionDoctor) {
            PermissionDoctorView(mediaKeyController: mediaKeyController, updateController: updateController)
                .toolbar(removing: .title)
                .toolbarBackground(.hidden, for: .windowToolbar)
                .containerBackground(.regularMaterial, for: .window)
                .windowMinimizeBehavior(.disabled)
                .windowFullScreenBehavior(.disabled)
        }
        .defaultLaunchBehavior(autoShowPermissionDoctor ? .presented : .suppressed)
        .windowBackgroundDragBehavior(.enabled)
        .windowResizability(.contentSize)
        .restorationBehavior(.disabled)
        .windowManagerRole(.associated)
    }
}
