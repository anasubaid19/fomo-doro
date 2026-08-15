import SwiftUI

struct SettingsView: View {
    @AppStorage("focusDuration") private var focus = 25
    @AppStorage("shortBreakDuration") private var shortBreak = 5
    @AppStorage("longBreakDuration") private var longBreak = 15
    @AppStorage("longBreakInterval") private var interval = 4
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("autostartNext") private var autostartNext = false

    var body: some View {
        Form {
            Section("Durations (minutes)") {
                Stepper("Focus: \(focus)", value: $focus, in: 1...120)
                Stepper("Short break: \(shortBreak)", value: $shortBreak, in: 1...60)
                Stepper("Long break: \(longBreak)", value: $longBreak, in: 1...120)
                Stepper("Long break every: \(interval) sessions", value: $interval, in: 1...12)
            }
            Section("Behavior") {
                Toggle("Play sound", isOn: $soundEnabled)
                Toggle("Auto-start next session", isOn: $autostartNext)
            }
        }
        .formStyle(.grouped)
    }
}
