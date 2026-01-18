import SwiftUI
import Observation

struct SettingsView: View {

    @State var controller: MediaKeyController

    var body: some View {
        VStack(alignment: .leading, spacing: 10.0) {
            Section(content: {
                Text(.appInfo)
            }, header: {
                HStack {
                    Text(.appName).bold()
                    Spacer(minLength: 0.0)
                    Menu(content: { Button(.quitButtonTitle, action: { NSApplication.shared.terminate(nil) }) },
                         label: { Image(systemName: "gearshape.fill") })
                    .buttonStyle(.borderless)
                }
            })

            Section(content: {
                VStack(alignment: .leading, spacing: 10.0) {
                    Toggle(.launchAtLoginSettingTitle, isOn: $controller.launchAtLogin)
                        .toggleStyle(.checkbox)
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
                }.padding(.leading, 10.0)
            }, header: { Text(.settingsSectionTitle).bold() })

            Section(content: {
                VStack(alignment: .leading, spacing: 10.0) {
                    HStack(spacing: 6.0) {
                        Image(systemName: systemImageName(for: controller.hasAccessibilityPermission))
                            .resizable()
                            .frame(width: 14.0, height: 14.0)
                            .foregroundStyle(color(for: controller.hasAccessibilityPermission))
                        Text(.accessibilityPermissionTitle)
                    }

                    ForEach(controller.appStates) { appState in
                        let (imageName, color, label): (String, Color, LocalizedStringResource) = {
                            switch appState.state {
                            case .notRunning:
                                return ("questionmark.circle.fill", .gray, .automationPermissionNotRunningTitle(appName: appState.appName))
                            case .runningWithDeniedAutomationAccess:
                                return ("xmark.circle.fill", .red, .automationPermissionTitle(appName: appState.appName))
                            case .runningWithPendingAutomationAccess:
                                return ("questionmark.circle.fill", .gray, .automationPermissionTitle(appName: appState.appName))
                            case .runningWithAutomationAccess:
                                return ("checkmark.circle.fill", .green, .automationPermissionTitle(appName: appState.appName))
                            }
                        }()

                        HStack(spacing: 6.0) {
                            Image(systemName: imageName)
                                .resizable()
                                .frame(width: 14.0, height: 14.0)
                                .foregroundStyle(color)
                            Text(label)
                        }
                    }
                }.padding(.leading, 10.0)
            }, header: { Text(.permissionsSectionTitle).bold() })
        }
        .controlSize(.small)
        .font(.system(size: 11.0))
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18.0)
        .padding(.vertical, 20.0)
        .formStyle(.grouped)
        // Being a menu extra means the app doesn't come frontmost when the UI is shown, so we need to help out a bit
        .onAppear { controller.noteUIShown() }
    }

    private func systemImageName(for value: Bool) -> String {
        switch value {
        case true: return "checkmark.circle.fill"
        case false: return "xmark.circle.fill"
        }
    }

    private func color(for value: Bool) -> Color {
        switch value {
        case true: return .green
        case false: return .red
        }
    }
}
