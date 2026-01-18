import SwiftUI
import Observation

struct SettingsView: View {

    @State var controller: MediaKeyController
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10.0) {
            Section(content: {
                Text(.appInfo)
            }, header: { Text(.appName).bold() })

            Section(content: {
                Toggle(.enableKeyholeSettingTitle, isOn: $controller.enabled)
                    .toggleStyle(.checkbox)

                Text(.targetNotRunningSettingTitle)
                    .disabled(!controller.enabled)
                Picker(.targetNotRunningSettingTitle, selection: $controller.targetNotRunningAction) {
                    ForEach(TargetNotRunningAction.allCases) {
                        Text($0.localizedDisplayValue)
                    }
                }
                .pickerStyle(.menu)
                .labelsVisibility(.hidden)
                .disabled(!controller.enabled)
            }, header: { Text(.settingsSectionTitle).bold() })

            Section(content: {
                Button(.quitButtonTitle, action: { NSApplication.shared.terminate(nil) })
            }, header: { Text(.utilitiesSectionTitle).bold() })
        }
        .controlSize(.small)
        .font(.system(size: 11.0))
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18.0)
        .padding(.vertical, 20.0)
        .formStyle(.grouped)
    }
}
