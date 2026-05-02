import Foundation
import Observation
import Combine

extension UserDefaultsKey {
    static var enableMusicAppRepeatModeFixing: UserDefaultsKey<Bool> {
        return .init("EnableMusicAppRepeatModeFixing", defaultValue: false)
    }

    static var musicAppTargetRepeatMode: UserDefaultsKey<MusicAppIntegration.TargetRepeatMode> {
        return .init("MusicAppTargetRepeatMode", defaultValue: .repeatAll)
    }

    static var musicAppRepeatModeFixCount: UserDefaultsKey<Int> {
        return .init("MusicAppRepeatModeFixCount", defaultValue: 0)
    }
}

@MainActor @Observable class MusicAppIntegration: ScriptableAppIntegration<MusicApplication> {

    override class var bundleId: String { return "com.apple.Music" }
    override class var appName: LocalizedStringResource { return .musicAppName }

    override init() {
        super.init()
        setupDistributedNotifications()
    }

    @MainActor deinit {
        teardownDistributedNotifications()
    }

    override func playPause() throws(MediaAppCommandError) {
        try scriptableApp().playpause?()
    }

    override func skipBack() throws(MediaAppCommandError) {
        try scriptableApp().backTrack?()
    }

    override func skipForward() throws(MediaAppCommandError) {
        try scriptableApp().nextTrack?()
    }

    // MARK: - Distributed Notifications & Fixing Repeat State

    enum TargetRepeatMode: String, UserDefaultsStoreableValue, Equatable, Hashable, Identifiable, CaseIterable {
        static func fromDefaultsStoredValue(_ value: Any) -> TargetRepeatMode? {
            guard let stringValue = value as? String else { return nil }
            return TargetRepeatMode(rawValue: stringValue)
        }

        var defaultsStoreableValue: Any { return rawValue }
        var id: String { return rawValue }

        case off
        case repeatOne
        case repeatAll

        var scriptingBridgeValue: MusicRepeatState {
            switch self {
            case .off: return .repeatOff
            case .repeatOne: return .repeatOne
            case .repeatAll: return .repeatAll
            }
        }
    }

    private let notificationDebounceSubject = PassthroughSubject<Notification, Never>()
    private var combineObservers = Set<AnyCancellable>()

    func setupDistributedNotifications() {
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(musicAppTrackChanged(_:)),
                                                            name: .init("com.apple.Music.playerInfo"),
                                                            object: nil, suspensionBehavior: .coalesce)
        notificationDebounceSubject.debounce(for: 2.0, scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] notification in
                self?.updateRepeatState(from: notification)
            }).store(in: &combineObservers)
    }

    func teardownDistributedNotifications() {
        DistributedNotificationCenter.default().removeObserver(self, name: .init("com.apple.Music.playerInfo"), object: nil)
        combineObservers.removeAll()
    }

    @objc private func musicAppTrackChanged(_ notification: Notification) {
        notificationDebounceSubject.send(notification)
    }

    private func updateRepeatState(from notification: Notification) {
        // We only want to futz with the Music app if the user wants us to, we have scripting permission and the app
        // is running, if we can get at the player state, and the Music app is "settled" in a playing state (i.e.,
        // isn't stopped or scrubbing).
        guard UserDefaults.standard.value(for: .enableMusicAppRepeatModeFixing) else { return }
        guard let app = try? scriptableApp() else { return }
        guard let playerState = app.playerState, let repeatState = app.songRepeat else { return }
        guard playerState == .playing || playerState == .paused else { return }

        let targetRepeatState = UserDefaults.standard.value(for: .musicAppTargetRepeatMode).scriptingBridgeValue

        if repeatState != targetRepeatState {
            LogInfo("Music app's repeat state (\(repeatState)) isn't what we want (\(targetRepeatState)). Fixing.")
            guard let nsApp = app as? (NSObject & MusicApplication) else { return }
            nsApp.setValue(targetRepeatState.rawValue, forKey: "songRepeat")
            // ^ https://forums.swift.org/t/compilation-error-in-assigning-to-obj-c-optional-protocol-property/53886

            let existingFixCount: Int = UserDefaults.standard.value(for: .musicAppRepeatModeFixCount)
            UserDefaults.standard.setValue(max(existingFixCount, 0) + 1, for: .musicAppRepeatModeFixCount)
        }
    }
}
