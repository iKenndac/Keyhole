import SwiftUI
import Observation

struct SettingsView: View {

    @State var controller: MediaKeyController
    @Environment(\.openWindow) var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 10.0) {
            Section(content: {
                Text(.appInfo)
            }, header: {
                HStack {
                    Text(.appName).bold()
                    Spacer(minLength: 0.0)
                    if let key = controller.currentlyPressedKey { Image(systemName: key.systemImageName) }
                    Menu(content: {
                        Button(.aboutMenuItemTitle, action: { NSApplication.shared.activate(); openWindow(id: "about") })
                        Divider()
                        Button(.quitButtonTitle, action: { NSApplication.shared.terminate(nil) })
                    }, label: { Image(systemName: "gearshape.fill") })
                    .buttonStyle(.borderless)
                }
            })

            Section(content: {
                VStack(alignment: .leading, spacing: 10.0) {
                    SettingsRow(.launchAtLoginSettingTitle) {
                        Toggle(.launchAtLoginSettingTitle, isOn: $controller.launchAtLogin)
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                            .labelsHidden()
                    }
                    SettingsRow(.enableKeyholeSettingTitle) {
                        Toggle(.enableKeyholeSettingTitle, isOn: $controller.enabled)
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                            .labelsHidden()
                    }

                }.padding(.leading, 10.0)
            }, header: { Text(.settingsSectionTitle).bold() })

            Section(content: {
                VStack(alignment: .leading, spacing: 10.0) {
                    if controller.availableTargets.count > 1 {
                        SettingsRow(.preferredMediaPlayerSettingTitle) {
                            Picker(.preferredMediaPlayerSettingTitle, selection: $controller.preferredTarget) {
                                ForEach(controller.availableTargets) {
                                    Text($0.appName)
                                        .tag($0)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsVisibility(.hidden)
                            .disabled(!controller.enabled)
                        }
                    }

                    SettingsRow(.targetNotRunningSettingTitle(appName: controller.preferredTarget.appName)) {
                        Picker(.targetNotRunningSettingTitle(appName: controller.preferredTarget.appName), selection: $controller.targetNotRunningAction) {
                            ForEach(TargetNotRunningAction.allCases) {
                                Text($0.localizedDisplayValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsVisibility(.hidden)
                        .disabled(!controller.enabled)
                    }
                }.padding(.leading, 10.0)
            }, header: { Text(.mediaKeyHandlingSectionTitle).bold() })

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
                                return ("questionmark.circle.fill", .gray.opacity(0.4), .automationPermissionNotRunningTitle(appName: appState.appName))
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

struct SettingsRow<V: View>: View {
    init(_ label: LocalizedStringResource, content: @escaping () -> V) {
        self.label = label
        self.content = content
    }

    let label: LocalizedStringResource
    @ViewBuilder let content: () -> V

    var body: some View {
        HStack {
            Text(label)
            Spacer(minLength: 6.0)
            content()
        }
        .frame(height: 20.0)
    }
}
