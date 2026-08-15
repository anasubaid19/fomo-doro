import SwiftUI
import AppKit
import ServiceManagement

struct SettingsView: View {
    @AppStorage("focusDuration") private var focus = 25
    @AppStorage("shortBreakDuration") private var shortBreak = 5
    @AppStorage("longBreakDuration") private var longBreak = 15
    @AppStorage("longBreakInterval") private var interval = 4
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("autostartNext") private var autostartNext = false

    @State private var launchError: String?
    @State private var updateResult: String?
    @State private var updateAvailable = false

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
                Toggle("Launch at login", isOn: launchAtLogin)
                if let error = launchError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            Section("About") {
                LabeledContent("Version", value: UpdateChecker.currentVersion)
                HStack {
                    Button("Check for updates") {
                        Task {
                            if let latest = await UpdateChecker.check() {
                                updateResult = "FomoDoro \(latest) is available"
                                updateAvailable = true
                            } else {
                                updateResult = "You're up to date"
                                updateAvailable = false
                            }
                        }
                    }
                    if let result = updateResult {
                        Text(result)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if updateAvailable {
                        Button("Download") {
                            NSWorkspace.shared.open(
                                URL(string: "https://github.com/anasubaid19/fomo-doro/releases/latest")!
                            )
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private var launchAtLogin: Binding<Bool> {
        Binding(
            get: { SMAppService.mainApp.status == .enabled },
            set: { enabled in
                do {
                    launchError = nil
                    if enabled {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    launchError = "Unable to change this setting: \(error.localizedDescription)"
                }
            }
        )
    }
}
