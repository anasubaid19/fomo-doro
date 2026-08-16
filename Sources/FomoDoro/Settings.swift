import Foundation
import AppKit

@MainActor
enum AppSettings {
    static let defaults = UserDefaults.standard

    enum Key {
        static let focusDuration = "focusDuration"
        static let shortBreakDuration = "shortBreakDuration"
        static let longBreakDuration = "longBreakDuration"
        static let longBreakInterval = "longBreakInterval"
        static let soundEnabled = "soundEnabled" // legacy v1.0/v1.1 toggle, kept for migration
        static let soundChoice = "soundChoice"
        static let autostartNext = "autostartNext"
        static let showMenuBarCountdown = "showMenuBarCountdown"
    }

    static func registerDefaults() {
        defaults.register(defaults: [
            Key.focusDuration: 25,
            Key.shortBreakDuration: 5,
            Key.longBreakDuration: 15,
            Key.longBreakInterval: 4,
            Key.soundEnabled: true,
            Key.autostartNext: false,
            Key.showMenuBarCountdown: true,
        ])
        if defaults.string(forKey: Key.soundChoice) == nil {
            let legacy = defaults.bool(forKey: Key.soundEnabled)
            defaults.set(legacy ? "system:Glass" : "none", forKey: Key.soundChoice)
        }
    }

    static var focusDuration: Int { defaults.integer(forKey: Key.focusDuration) }
    static var shortBreakDuration: Int { defaults.integer(forKey: Key.shortBreakDuration) }
    static var longBreakDuration: Int { defaults.integer(forKey: Key.longBreakDuration) }
    static var longBreakInterval: Int { defaults.integer(forKey: Key.longBreakInterval) }
    static var soundChoice: String { defaults.string(forKey: Key.soundChoice) ?? "system:Glass" }
    static var autostartNext: Bool { defaults.bool(forKey: Key.autostartNext) }
    static var showMenuBarCountdown: Bool { defaults.bool(forKey: Key.showMenuBarCountdown) }
}

@MainActor
enum SoundPlayer {
    static let systemPresets = ["Glass", "Ping", "Pop", "Submarine", "Basso", "Funk"]

    static func play(_ choice: String) {
        let parts = choice.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            .map(String.init)
        guard parts.count == 2 else { return } // "none"
        switch parts[0] {
        case "system":
            NSSound(named: parts[1])?.play()
        case "custom":
            // ponytail: plain path access (no sandbox); deleted/moved file → silent skip
            guard FileManager.default.fileExists(atPath: parts[1]) else { return }
            NSSound(contentsOfFile: parts[1], byReference: false)?.play()
        default:
            break
        }
    }
}
