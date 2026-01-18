import SwiftUI
import Observation

struct SettingsView: View {

    @State var controller: MediaKeyController
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(.targetNotRunningSettingTitle)

            Picker(.targetNotRunningSettingTitle, selection: $controller.targetNotRunningAction) {
                ForEach(TargetNotRunningAction.allCases) {
                    Text($0.localizedDisplayValue)
                }
            }
            .pickerStyle(.menu)
            .labelsVisibility(.hidden)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18.0)
        .padding(.vertical, 20.0)
    }
}
