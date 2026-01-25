import Foundation
import SwiftUI

extension UserDefaultsKey {
    static var hasCompletedOnboarding: UserDefaultsKey<Bool> {
        return .init("HasCompletedOnboarding", defaultValue: false, shouldRegister: false)
    }
}

extension MediaKeyController.MediaAppDetailsWithState {

    var appIcon: Image {
        let workspace = NSWorkspace.shared
        guard let url = workspace.urlForApplication(withBundleIdentifier: bundleId) else {
            return Image(.blankAppIcon)
        }
        let icon = workspace.icon(forFile: url.path(percentEncoded: false))
        icon.size = NSSize(width: 48.0, height: 48.0)
        return Image(nsImage: icon)
    }

    var grantStatus: PermissionGrantView.GrantStatus {
        switch state {
        case .notRunning: return .pending
        case .runningWithDeniedAutomationAccess: return .denied
        case .runningWithPendingAutomationAccess: return .pending
        case .runningWithAutomationAccess: return.granted
        }
    }
}

struct PermissionGrantView: View {

    enum GrantStatus: Equatable {
        case pending
        case granted
        case denied
    }

    let status: GrantStatus
    let grantButtonTitle: LocalizedStringResource
    let grantButtonAction: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 6.0) {
            if status == .granted {
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .resizable()
                    .frame(width: 20.0, height: 20.0)
                    .foregroundStyle(.white, .green.gradient)
                Text(.permissionGrantedStatusTitle).bold()
            } else {
                Button(grantButtonTitle, action: grantButtonAction)
            }
        }
        .frame(height: 26.0)
    }
}

struct PermissionDoctorView: View {

    @State var mediaKeyController: MediaKeyController
    @State var updateController: UpdateController

    @State var showingMissingPermissionsSheet: Bool = false
    @State var showingGoodToGoSheet: Bool = false
    @Environment(\.dismissWindow) var dismissWindow
    
    var scrollablePermissionsArea: Bool {
        // If the user has more than a couple of supported apps installed, we'll get out of hand quite quickly
        // if we don't allow the list to scroll. Otherwise, prefer to show everything.
        return mediaKeyController.appStates.count > 2
    }

    func performContinueAction() {
        let isGoodToGo: Bool = (mediaKeyController.hasAccessibilityPermission &&
            mediaKeyController.appStates.contains(where: { $0.state != .runningWithDeniedAutomationAccess }))

        if isGoodToGo {
            if !UserDefaults.standard.value(for: .hasCompletedOnboarding) {
                // If this is the first time the user has used the app, set the preferred app to an
                // app the user has granted permission to.
                if let granted = mediaKeyController.appStates.first(where: { $0.state == .runningWithAutomationAccess }),
                   let target = mediaKeyController.availableTargets.first(where: { $0.bundleId == granted.bundleId }) {
                    mediaKeyController.preferredTarget = target
                }
            }
            showingGoodToGoSheet = true
        } else {
            showingMissingPermissionsSheet = true
        }
    }

    func performAccessibilityGrantAction() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            NSSound.beep()
            return
        }
        NSWorkspace.shared.open(url)
    }

    func performAppGrantAction(for app: MediaKeyController.MediaAppDetailsWithState) {
        guard let target = mediaKeyController.integrations.first(where: { $0.bundleId == app.bundleId }) else {
            NSSound.beep()
            return
        }

        Task {
            do {
                try await target.launchApplication(askingForAutomationPermission: true)
            } catch let error as MediaAppCommandError {
                if error == .automationDenied || error == .automationPending {
                    guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") else {
                        NSSound.beep()
                        return
                    }
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    var body: some View {
        VStack(alignment: .center, spacing: scrollablePermissionsArea ? 10.0 : 0.0) {
            VStack(alignment: .center, spacing: 12.0) {
                Image(.keyholeIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 96.0)
                    .fixedSize()
                    .shadow(color: .black.opacity(0.4), radius: 1.0, x: 0.5, y: 0.5)
                VStack(alignment: .center, spacing: 8.0) {
                    Text(.permissionDoctorIntroText)
                        .padding(.horizontal, 20.0)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            }.allowsHitTesting(false)
            Form {
                Section {
                    HStack(alignment: .top, spacing: 8.0) {
                        Image(systemName: "accessibility.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40.0)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .blue.gradient)
                            .padding(.horizontal, 12.0)
                            .padding(.top, 4.0)
                            .compositingGroup()
                            .shadow(color: .black.opacity(0.4), radius: 1.0, x: 0.5, y: 0.5)
                        VStack(alignment: .leading, spacing: 8.0) {
                            Text(.accessibilityPermissionTitle).bold()
                            Text(.permissionDoctorAccessibilityText)
                                .font(.system(size: 11.0))
                            PermissionGrantView(status: mediaKeyController.hasAccessibilityPermission ? .granted : .denied,
                                                grantButtonTitle: .permissionDoctorGrantPermissionButtonTitle,
                                                grantButtonAction: performAccessibilityGrantAction)

                        }
                    }
                    .padding(.vertical, 4.0)
                }

                ForEach(mediaKeyController.appStates) { state in
                    Section {
                        HStack(alignment: .top, spacing: 8.0) {
                            state.appIcon
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 48.0)
                                .padding(.horizontal, 8.0)
                            VStack(alignment: .leading, spacing: 8.0) {
                                Text(verbatim: state.appName).bold()
                                Text(.permissionDoctorAppAutomationText(appName: state.appName))
                                    .font(.system(size: 11.0))
                                PermissionGrantView(status: state.grantStatus,
                                                    grantButtonTitle: .permissionDoctorGrantPermissionButtonTitle,
                                                    grantButtonAction: { performAppGrantAction(for: state) })

                            }
                        }
                        .padding(.vertical, 4.0)
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: !scrollablePermissionsArea)
            .scrollDisabled(!scrollablePermissionsArea)
            .scrollBounceBehavior(.basedOnSize)
            .formStyle(.grouped)

            HStack {
                Button(.continueButtonTitle, action: performContinueAction)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(.bottom, 20.0)
        .frame(width: 600.0)
        .onCondition(scrollablePermissionsArea) { $0.frame(height: 650.0) }
        .onAppear {
            // Being a menu extra means the app doesn't come frontmost when the UI is shown, so we need to help out a bit.
            // Since this window is *big* and having it be floating like our other windows is kinda rude, let's be a
            // normal app for a bit.
            NSApplication.shared.setActivationPolicy(.regular)
            // This is kinda gross, but since we're usually an accessory app we'll appear behind whatever window is
            // currently active unless we force our way to the front.
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        .onDisappear {
            UserDefaults.standard.setValue(true, for: .hasCompletedOnboarding)
            NSApplication.shared.setActivationPolicy(.accessory)
        }
        .alert(.permissionDoctorMissingPermissionAlertTitle, isPresented: $showingMissingPermissionsSheet, actions: {
            Button(role: .cancel, action: { showingMissingPermissionsSheet = false }, label: { Text(.cancelButtonTitle) })
            Button(role: nil, action: {
                showingMissingPermissionsSheet = false
                // This is stupid, but dismissing the window immediately doesn't work.
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    dismissWindow.callAsFunction(id: KeyholeApp.WindowId.permissionDoctor)
                }
            }, label: { Text(.permissionDoctorMissingPermissionAlertConfirmationButtonTitle) })
        }, message: { Text(.permissionDoctorMissingPermissionAlertMessage) })
        .alert(.permissionDoctorAllOKAlertTitle, isPresented: $showingGoodToGoSheet, actions: {
            Button(role: nil, action: {
                showingGoodToGoSheet = false
                // This is stupid, but dismissing the window immediately doesn't work.
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    dismissWindow.callAsFunction(id: KeyholeApp.WindowId.permissionDoctor)
                }
            }, label: { Text(.continueButtonTitle) })
        }, message: { Text(.permissionDoctorAllOKAlertMessage) })
    }
}
