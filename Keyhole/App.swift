import SwiftUI

@main
struct KeyholeApp: App {

    let controller: MediaKeyController

    init() {
        controller = MediaKeyController()
    }

    var body: some Scene {
        MenuBarExtra(.appName, systemImage: controller.enabled ? "play.fill" : "play.slash.fill") {
            SettingsView(controller: controller)
                .frame(maxHeight: .infinity)
        }
        .menuBarExtraStyle(.window)
    }
}
