import Foundation

@MainActor
enum AppSettings {
    static let defaults = UserDefaults.standard

    enum Key {
        static let focusDuration = "focusDuration"
        static let shortBreakDuration = "shortBreakDuration"
        static let longBreakDuration = "longBreakDuration"
        static let longBreakInterval = "longBreakInterval"
        static let soundEnabled = "soundEnabled"
        static let autostartNext = "autostartNext"
    }

    static func registerDefaults() {
        defaults.register(defaults: [
            Key.focusDuration: 25,
            Key.shortBreakDuration: 5,
            Key.longBreakDuration: 15,
            Key.longBreakInterval: 4,
            Key.soundEnabled: true,
            Key.autostartNext: false,
        ])
    }

    static var focusDuration: Int { defaults.integer(forKey: Key.focusDuration) }
    static var shortBreakDuration: Int { defaults.integer(forKey: Key.shortBreakDuration) }
    static var longBreakDuration: Int { defaults.integer(forKey: Key.longBreakDuration) }
    static var longBreakInterval: Int { defaults.integer(forKey: Key.longBreakInterval) }
    static var soundEnabled: Bool { defaults.bool(forKey: Key.soundEnabled) }
    static var autostartNext: Bool { defaults.bool(forKey: Key.autostartNext) }
}
