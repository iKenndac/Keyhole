import SwiftUI

@main
struct KeyholeApp: App {

    let controller: MediaKeyController

    init() {
        controller = MediaKeyController()
    }

    var body: some Scene {
        MenuBarExtra(.appName, systemImage: "playpause.fill") {
            SettingsView(controller: controller)
                .frame(maxHeight: .infinity)
        }
        .menuBarExtraStyle(.window)
    }
}
