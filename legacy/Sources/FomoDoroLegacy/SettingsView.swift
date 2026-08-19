import SwiftUI
import AppKit
import UniformTypeIdentifiers

private enum Preset: String, CaseIterable, Identifiable {
    case classic, deepWork, sprint, custom

    var id: String { rawValue }

    var focus: Int {
        switch self {
        case .classic: return 25
        case .deepWork: return 50
        case .sprint: return 15
        case .custom: return 0
        }
    }

    var shortBreak: Int {
        switch self {
        case .classic: return 5
        case .deepWork: return 10
        case .sprint: return 3
        case .custom: return 0
        }
    }

    var title: String {
        switch self {
        case .classic: return "Classic — 25/5"
        case .deepWork: return "Deep Work — 50/10"
        case .sprint: return "Sprint — 15/3"
        case .custom: return "Custom"
        }
    }
}

struct SettingsView: View {
    @AppStorage("focusDuration") private var focus = 25
    @AppStorage("shortBreakDuration") private var shortBreak = 5
    @AppStorage("longBreakDuration") private var longBreak = 15
    @AppStorage("longBreakInterval") private var interval = 4
    @AppStorage("soundChoice") private var soundChoice = "system:Glass"
    @AppStorage("autostartNext") private var autostartNext = false
    @AppStorage("showMenuBarCountdown") private var showMenuBarCountdown = true
    @AppStorage("dailyGoal") private var dailyGoal = 8
    @AppStorage("autoOpenPopoverOnCompletion") private var autoOpenPopoverOnCompletion = true

    @State private var launchError: String?
    @State private var updateResult: String?
    @State private var updateAvailable = false
    @State private var showFileImporter = false

    private var isCustomSound: Bool { soundChoice.hasPrefix("custom:") }

    private var customFileName: String {
        guard isCustomSound else { return "" }
        let path = String(soundChoice.dropFirst("custom:".count))
        return URL(fileURLWithPath: path).lastPathComponent
    }

    var body: some View {
        ScrollView {
            Form {
                Section("Durations (minutes)") {
                Picker("Preset", selection: presetBinding) {
                    ForEach(Preset.allCases) { preset in
                        Text(preset.title).tag(preset)
                    }
                }
                Stepper("Focus: \(focus)", value: $focus, in: 1...120)
                Stepper("Short break: \(shortBreak)", value: $shortBreak, in: 1...60)
                Stepper("Long break: \(longBreak)", value: $longBreak, in: 1...120)
                Stepper("Long break every: \(interval) sessions", value: $interval, in: 1...12)
            }
            Section("Goal") {
                Stepper("Daily goal: \(dailyGoal) sessions", value: $dailyGoal, in: 1...24)
            }
            Section("Behavior") {
                Toggle("Auto-start next session", isOn: $autostartNext)
                Toggle("Auto-open popover when a session ends", isOn: $autoOpenPopoverOnCompletion)
                Toggle("Show countdown in menu bar", isOn: $showMenuBarCountdown)

                Picker("Completion sound", selection: $soundChoice) {
                    Text("None").tag("none")
                    ForEach(SoundPlayer.systemPresets, id: \.self) { name in
                        Text(name).tag("system:\(name)")
                    }
                    if isCustomSound {
                        Text("Custom file").tag(soundChoice)
                    }
                }

                HStack {
                    Button("Choose sound file…") { showFileImporter = true }
                    Button("Preview") { SoundPlayer.play(soundChoice) }
                    if isCustomSound {
                        Text(customFileName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            Section("General") {
                Toggle("Launch at login", isOn: launchAtLogin)
                if let error = launchError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(UpdateChecker.currentVersion)
                        .foregroundStyle(.secondary)
                }
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
                Button("Quit FomoDoro") {
                    NSApplication.shared.terminate(nil)
                }
            }
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.audio]
        ) { result in
            if case .success(let url) = result {
                soundChoice = "custom:\(url.path)"
            }
        }
    }

    private var launchAtLogin: Binding<Bool> {
        Binding(
            get: { LegacyLaunchAtLogin.isEnabled },
            set: { enabled in
                do {
                    launchError = nil
                    try LegacyLaunchAtLogin.setEnabled(enabled)
                } catch {
                    launchError = "Unable to change this setting: \(error.localizedDescription)"
                }
            }
        )
    }

    private var presetBinding: Binding<Preset> {
        Binding(
            get: {
                let matches = Preset.allCases.filter {
                    $0 != .custom && $0.focus == focus && $0.shortBreak == shortBreak && longBreak == 15
                }
                return matches.first ?? .custom
            },
            set: { newPreset in
                guard newPreset != .custom else { return }
                focus = newPreset.focus
                shortBreak = newPreset.shortBreak
                longBreak = 15
            }
        )
    }
}
