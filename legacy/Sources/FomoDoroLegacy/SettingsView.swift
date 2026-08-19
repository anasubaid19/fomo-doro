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
            VStack(alignment: .leading, spacing: 16) {
                LegacySettingsSection(title: "Durations") {
                    HStack(spacing: 12) {
                        Text("Preset")
                        Spacer(minLength: 8)
                        Picker("Preset", selection: presetBinding) {
                            ForEach(Preset.allCases) { preset in
                                Text(preset.title).tag(preset)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 190)
                    }

                    LegacyStepperRow(title: "Focus", value: $focus, range: 1...120, suffix: " min")
                    LegacyStepperRow(title: "Short break", value: $shortBreak, range: 1...60, suffix: " min")
                    LegacyStepperRow(title: "Long break", value: $longBreak, range: 1...120, suffix: " min")
                    LegacyStepperRow(
                        title: "Long break every",
                        value: $interval,
                        range: 1...12,
                        suffix: " sessions"
                    )
                }

                LegacySettingsSection(title: "Goal") {
                    LegacyStepperRow(
                        title: "Daily goal",
                        value: $dailyGoal,
                        range: 1...24,
                        suffix: " sessions"
                    )
                }

                LegacySettingsSection(title: "Behavior") {
                    Toggle("Auto-start next session", isOn: $autostartNext)
                        .toggleStyle(.checkbox)
                    Toggle("Auto-open when session ends", isOn: $autoOpenPopoverOnCompletion)
                        .toggleStyle(.checkbox)
                    Toggle("Show countdown in menu bar", isOn: $showMenuBarCountdown)
                        .toggleStyle(.checkbox)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Completion sound")
                            .font(.subheadline.weight(.medium))
                        Picker("Completion sound", selection: $soundChoice) {
                            Text("None").tag("none")
                            ForEach(SoundPlayer.systemPresets, id: \.self) { name in
                                Text(name).tag("system:\(name)")
                            }
                            if isCustomSound {
                                Text("Custom file").tag(soundChoice)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: .infinity)

                        HStack(spacing: 8) {
                            Button("Choose sound file…") { showFileImporter = true }
                            Button("Preview") { SoundPlayer.play(soundChoice) }
                            Spacer(minLength: 0)
                        }
                        if isCustomSound {
                            Text(customFileName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .help(customFileName)
                        }
                    }
                }

                LegacySettingsSection(title: "General") {
                    Toggle("Launch at login", isOn: launchAtLogin)
                        .toggleStyle(.checkbox)
                    if let error = launchError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                LegacySettingsSection(title: "About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(UpdateChecker.currentVersion)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }

                    HStack(spacing: 8) {
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
                        if updateAvailable {
                            Button("Download") {
                                NSWorkspace.shared.open(
                                    URL(string: "https://github.com/anasubaid19/fomo-doro/releases/latest")!
                                )
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    if let result = updateResult {
                        Text(result)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Button("Quit FomoDoro") {
                        NSApplication.shared.terminate(nil)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 4)
            .padding(.bottom, 14)
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

private struct LegacySettingsSection<Content: View>: View {
    let title: String
    private let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            VStack(alignment: .leading, spacing: 10) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.secondary.opacity(0.08))
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct LegacyStepperRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let suffix: String

    var body: some View {
        Stepper(value: $value, in: range) {
            HStack(spacing: 8) {
                Text(title)
                Spacer(minLength: 8)
                Text("\(value)\(suffix)")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }
}
