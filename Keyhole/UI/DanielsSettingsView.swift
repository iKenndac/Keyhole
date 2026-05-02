import Foundation
import SwiftUI

struct DanielsSettingsView: View {

    @AppStorage(UserDefaultsKey<Bool>.enableMusicAppRepeatModeFixing.identifier)
    private var enableMusicRepeatModeFixing: Bool = false

    @AppStorage(UserDefaultsKey<Int>.musicAppRepeatModeFixCount.identifier)
    private var musicRepeatModeFixCount: Int = 0

    // We can't use @AppStorage for this since it needs our UserDefaults wrapper.
    @State private var targetMusicRepeatMode: MusicAppIntegration.TargetRepeatMode

    init() {
        _targetMusicRepeatMode = .init(initialValue: UserDefaults.standard.value(for: .musicAppTargetRepeatMode))
    }

    // For whatever reason, our form sections are _way_ too far apart with applying this to our headers :-/
    private let formSectionSpacingFix: CGFloat = -12.0

    var body: some View {
        Form {
            Section(content: {
                VStack(alignment: .leading, spacing: 14.0) {
                    SettingsRow(.fixMusicAppRepeatSettingTitle) {
                        Toggle(.fixMusicAppRepeatSettingTitle, isOn: $enableMusicRepeatModeFixing)
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .labelsHidden()
                    }

                    SettingsRow(.fixMusicAppRepeatTargetSettingTitle) {
                        Picker(.fixMusicAppRepeatTargetSettingTitle, selection: $targetMusicRepeatMode) {
                            ForEach(MusicAppIntegration.TargetRepeatMode.allCases) {
                                Text($0.localizedDisplayValue)
                                    .tag($0)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsVisibility(.hidden)
                        .disabled(!enableMusicRepeatModeFixing)
                    }

                    Divider()

                    Text(.fixMusicAppRepeatSettingFooter)
                        .font(.system(size: 11.0))

                    Text(.musicAppRepeatModeFixedStat(fixCount: musicRepeatModeFixCount))
                        .font(.system(size: 11.0))
                }
            }, header: { Text(.danielsSettingsMusicAppSectionTitle).bold().padding(.top, formSectionSpacingFix) })
        }
        .fixedSize(horizontal: false, vertical: true)
        .scrollDisabled(true)
        .controlSize(.regular)
        .font(.system(size: 13.0))
        .frame(width: 450.0)
        .formStyle(.grouped)
        .onChange(of: targetMusicRepeatMode, { _, new in
            UserDefaults.standard.setValue(new, for: .musicAppTargetRepeatMode)
        })
    }
}
