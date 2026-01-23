import SwiftUI
import Observation

struct SettingsView: View {

    @State var mediaKeyController: MediaKeyController
    @State var updateController: UpdateController
    @Environment(\.openWindow) var openWindow

    // For whatever reason, our form sections are _way_ too far apart with applying this to our headers :-/
    private let formSectionSpacingFix: CGFloat = -12.0

    private func showPermissionDoctor() {
        NSApplication.shared.activate()
        openWindow(id: KeyholeApp.WindowId.permissionDoctor)
    }

    var body: some View {
        Form {
            Section(content: {
                Text(.appInfo)
                    .fixedSize(horizontal: false, vertical: true)
            }, header: {
                HStack {
                    Text(.appName).font(.system(size: 15.0)).bold()
                    Spacer(minLength: 0.0)
                    if let key = mediaKeyController.currentlyPressedKey { Image(systemName: key.systemImageName) }
                    Menu(content: {
                        Button(.aboutMenuItemTitle, action: {
                            NSApplication.shared.activate()
                            openWindow(id: KeyholeApp.WindowId.about)
                        })
                        Divider()
                        Button(.showPermissionDoctorMenuTitle, action: showPermissionDoctor)
                        Divider()
                        Button(.checkForUpdatesMenuTitle, action: { updateController.checkForUpdates() })
                        Divider()
                        Button(.quitButtonTitle, action: { NSApplication.shared.terminate(nil) })
                    }, label: { Image(systemName: "gearshape.fill") })
                    .buttonStyle(.borderless)
                }.padding(.trailing, -10.0) // Make the menu aligned with the section container edge
            })

            Section(content: {
                VStack(alignment: .leading, spacing: 10.0) {
                    SettingsRow(.launchAtLoginSettingTitle) {
                        Toggle(.launchAtLoginSettingTitle, isOn: $mediaKeyController.launchAtLogin)
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                            .labelsHidden()
                    }
                    SettingsRow(.automaticallyCheckForUpdatesSettingTitle) {
                        Toggle(.automaticallyCheckForUpdatesSettingTitle, isOn: $updateController.automaticallyCheckForUpdates)
                            .disabled(!updateController.executionEnvironmentAllowsUpdates)
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                            .labelsHidden()
                    }

                    if !updateController.executionEnvironmentAllowsUpdates {
                        HStack(spacing: 4.0) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            SettingsRow(.updatesUnavailableTitle) {
                                // Telling the update controller to check for updates will show an explanation dialog.
                                Button(.fixPermissionButtonTitle, action: { updateController.checkForUpdates() })
                            }
                        }

                    } else if updateController.updateAvailable {
                        HStack(spacing: 4.0) {
                            Image(systemName: "arrow.up.circle.fill")
                            SettingsRow(.updateAvailableTitle) {
                                Button(.showPendingUpdateInfoButtonTitle, action: { updateController.checkForUpdates() })
                            }
                        }
                    }
                }
            }, header: { Text(.settingsSectionTitle).bold().padding(.top, formSectionSpacingFix) })

            Section(content: {
                VStack(alignment: .leading, spacing: 10.0) {
                    SettingsRow(.enableKeyholeSettingTitle) {
                        Toggle(.enableKeyholeSettingTitle, isOn: $mediaKeyController.enabled)
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                            .labelsHidden()
                    }

                    if mediaKeyController.availableTargets.count > 1 {
                        SettingsRow(.preferredMediaPlayerSettingTitle) {
                            Picker(.preferredMediaPlayerSettingTitle, selection: $mediaKeyController.preferredTarget) {
                                ForEach(mediaKeyController.availableTargets) {
                                    Text($0.appName)
                                        .tag($0)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsVisibility(.hidden)
                            .disabled(!mediaKeyController.enabled)
                        }
                    }

                    SettingsRow(.targetNotRunningSettingTitle(appName: mediaKeyController.preferredTarget.appName)) {
                        Picker(.targetNotRunningSettingTitle(appName: mediaKeyController.preferredTarget.appName), selection: $mediaKeyController.targetNotRunningAction) {
                            ForEach(TargetNotRunningAction.allCases) {
                                Text($0.localizedDisplayValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsVisibility(.hidden)
                        .disabled(!mediaKeyController.enabled)
                    }
                }
            }, header: { Text(.mediaKeyHandlingSectionTitle).bold().padding(.top, formSectionSpacingFix) })

            if mediaKeyController.hasPermissionsProblem {
                Section(content: {
                    VStack(alignment: .leading, spacing: 10.0) {
                        HStack(spacing: 6.0) {
                            Image(systemName: systemImageName(for: mediaKeyController.hasAccessibilityPermission))
                                .symbolRenderingMode(.palette)
                                .resizable()
                                .frame(width: 14.0, height: 14.0)
                                .foregroundStyle(.white, color(for: mediaKeyController.hasAccessibilityPermission).gradient)
                            Text(.accessibilityPermissionTitle)
                            Button(.fixPermissionButtonTitle, action: showPermissionDoctor)
                                .onCondition(mediaKeyController.hasAccessibilityPermission, transform: { $0.hidden() })
                        }

                        ForEach(mediaKeyController.appStates) { appState in
                            let (imageName, color, label): (String, Color, LocalizedStringResource) = {
                                switch appState.state {
                                case .notRunning:
                                    return ("questionmark.circle.fill", .gray.opacity(0.6), .automationPermissionNotRunningTitle(appName: appState.appName))
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
                                    .symbolRenderingMode(.palette)
                                    .resizable()
                                    .frame(width: 14.0, height: 14.0)
                                    .foregroundStyle(.white, color.gradient)
                                Text(label)
                                Button(.fixPermissionButtonTitle, action: showPermissionDoctor)
                                    .onCondition(appState.state != .runningWithDeniedAutomationAccess, transform: { $0.hidden() })
                            }
                        }
                    }
                }, header: { Text(.permissionsSectionTitle).bold().padding(.top, formSectionSpacingFix) })
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .scrollDisabled(true)
        .controlSize(.small)
        .font(.system(size: 11.0))
        .frame(width: 320.0) // If it was good enough for the original iPhone, it's good enough for us!
        .formStyle(.grouped)
        // Being a menu extra means the app doesn't come frontmost when the UI is shown, so we need to help out a bit
        .onAppear { mediaKeyController.noteUIShown() }
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
            Spacer(minLength: 0.0)
            content()
        }
        .frame(height: 20.0)
    }
}
