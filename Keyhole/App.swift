import SwiftUI

@main
struct KeyholeApp: App {

    let controller: MediaKeyController

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
        }
        .menuBarExtraStyle(.window)
    }
}
