import SwiftUI

@main
struct KeyholeApp: App {

    let controller: MediaKeyController
    @Environment(\.openWindow) var openWindow

    init() {
        controller = MediaKeyController()
    }

    var menuBarImageName: String {
        if controller.enabled {
            if controller.hasPermissionsProblem {
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
            SettingsView(controller: controller)
                .frame(maxHeight: .infinity)
                .containerBackground(.regularMaterial, for: .window)
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(replacing: .appInfo) {
                // Probably unneeded since we're an agent, but oh well.
                Button { openWindow(id: "about") } label: { Text(.aboutMenuItemTitle) }
            }
        }

        Window(.aboutWindowTitle, id: "about") {
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
    }
}
