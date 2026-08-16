import Foundation
import AppKit
import UserNotifications
import SwiftData

enum TimerPhase: Equatable {
    case idle
    case running(SessionKind)
    case paused(SessionKind)
}

@MainActor
final class TimerStore: ObservableObject {
    @Published var phase: TimerPhase = .idle
    @Published var remaining: Double = 0
    @Published var cycleCount: Int = 0
    @Published var activeTask: TaskItem?
    @Published var justCompletedFocus: FocusSession?

    private let modelContext: ModelContext
    private var tickTask: Task<Void, Never>?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        restoreState()
        startTickLoop()
    }

    var isRunning: Bool {
        if case .running = phase { return true }
        return false
    }

    var currentKind: SessionKind? {
        switch phase {
        case .running(let k), .paused(let k): return k
        case .idle: return nil
        }
    }

    var totalForCurrentPhase: Int {
        duration(for: currentKind ?? .focus) * 60
    }

    var displaySeconds: Int { max(0, Int(remaining.rounded(.up))) }

    var menuBarText: String {
        guard AppSettings.showMenuBarCountdown else { return "🍅" }
        switch phase {
        case .idle: return "🍅"
        case .running, .paused: return (isRunning ? "🍅 " : "⏸ ") + format(displaySeconds)
        }
    }

    var timeText: String { format(displaySeconds) }

    var voiceOverText: String {
        let time = "\(displaySeconds / 60) minutes \(displaySeconds % 60) seconds"
        switch phase {
        case .idle: return "FomoDoro idle"
        case .running(let kind): return "\(kindName(kind)), \(time) remaining"
        case .paused(let kind): return "Paused, \(kindName(kind)), \(time) remaining"
        }
    }

    private func kindName(_ kind: SessionKind) -> String {
        switch kind {
        case .focus: return "Focus"
        case .shortBreak: return "Short break"
        case .longBreak: return "Long break"
        }
    }

    func duration(for kind: SessionKind) -> Int {
        switch kind {
        case .focus: return AppSettings.focusDuration
        case .shortBreak: return AppSettings.shortBreakDuration
        case .longBreak: return AppSettings.longBreakDuration
        }
    }

    func resetToIdle() {
        phase = .idle
        remaining = Double(AppSettings.focusDuration * 60)
        persistState()
    }

    func startFocus() {
        remaining = Double(AppSettings.focusDuration * 60)
        phase = .running(.focus)
        persistState()
    }

    func startBreak(_ kind: SessionKind) {
        remaining = Double(duration(for: kind) * 60)
        phase = .running(kind)
        persistState()
    }

    func togglePause() {
        switch phase {
        case .running(let k): phase = .paused(k)
        case .paused(let k): phase = .running(k)
        case .idle:
            justCompletedFocus = nil
            startFocus()
        }
        persistState()
    }

    func dismissCompletionBanner() {
        justCompletedFocus = nil
    }

    func skip() {
        justCompletedFocus = nil
        guard currentKind != nil else {
            startFocus()
            return
        }
        completeSession(manual: true)
    }

    func reset() {
        resetToIdle()
        cycleCount = 0
        activeTask = nil
        justCompletedFocus = nil
        persistState()
    }

    private func startTickLoop() {
        tickTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                self?.tick()
            }
        }
    }

    private var lastPersistedSecond: Int?

    private func tick() {
        guard isRunning else { return }
        // ponytail: 0.1s decrement accumulates negligible float error over a 25-min
        // session; switch to a wall-clock endDate if sub-second accuracy ever matters.
        remaining -= 0.1
        if remaining <= 0 {
            completeSession()
            return
        }
        let second = displaySeconds
        if second != lastPersistedSecond {
            lastPersistedSecond = second
            persistState()
        }
    }

    private func completeSession(manual: Bool = false) {
        guard let kind = currentKind else { return }

        let session = FocusSession(
            kind: kind,
            start: Date(),
            durationSeconds: duration(for: kind) * 60,
            taskTitle: activeTask?.title
        )
        modelContext.insert(session)

        if kind == .focus {
            cycleCount += 1
            if let task = activeTask {
                task.completed += 1
                if task.estimate > 0 && task.completed >= task.estimate {
                    task.isDone = true
                    task.completedAt = Date()
                }
            }
        }

        try? modelContext.save()
        if !manual {
            playCompletionSound()
            sendNotification(for: kind)
            if kind == .focus {
                justCompletedFocus = session
            }
        }

        advanceAfterCompletion(alwaysAdvance: manual)
    }

    private func advanceAfterCompletion(alwaysAdvance: Bool) {
        guard let kind = currentKind else { return }
        switch kind {
        case .focus:
            if cycleCount % AppSettings.longBreakInterval == 0 {
                startBreak(.longBreak)
            } else if alwaysAdvance || AppSettings.autostartNext {
                startBreak(.shortBreak)
            } else {
                resetToIdle()
            }
        case .shortBreak, .longBreak:
            if alwaysAdvance || AppSettings.autostartNext {
                startFocus()
            } else {
                resetToIdle()
            }
        }
    }

    private func playCompletionSound() {
        SoundPlayer.play(AppSettings.soundChoice)
    }

    // ponytail: UNUserNotificationCenter requires a real .app bundle; bare `swift run` has none.
    private var notificationsAvailable: Bool { Bundle.main.bundleIdentifier != nil }

    private func sendNotification(for kind: SessionKind) {
        guard notificationsAvailable else { return }
        let content = UNMutableNotificationContent()
        switch kind {
        case .focus:
            content.title = "Focus session complete"
            content.body = "Time for a break."
        case .shortBreak, .longBreak:
            content.title = "Break over"
            content.body = "Ready to focus?"
        }
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func requestNotificationPermission() {
        guard notificationsAvailable else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    // MARK: - Persistence

    private struct PersistedState: Codable {
        var kindRaw: String?
        var paused: Bool
        var remaining: Double
        var cycleCount: Int
    }

    private static let stateKey = "timerState"

    private func persistState() {
        let kindRaw: String?
        let paused: Bool
        switch phase {
        case .idle: kindRaw = nil; paused = false
        case .running(let k): kindRaw = k.rawValue; paused = false
        case .paused(let k): kindRaw = k.rawValue; paused = true
        }
        let state = PersistedState(
            kindRaw: kindRaw,
            paused: paused,
            remaining: remaining,
            cycleCount: cycleCount
        )
        if let data = try? JSONEncoder().encode(state) {
            AppSettings.defaults.set(data, forKey: Self.stateKey)
        }
    }

    // ponytail: saves up to 1s stale (persist once per integer second); active task is
    // not restored across relaunch — re-tap a task after logging back in.
    private func restoreState() {
        guard let data = AppSettings.defaults.data(forKey: Self.stateKey),
              let state = try? JSONDecoder().decode(PersistedState.self, from: data)
        else {
            phase = .idle
            remaining = Double(AppSettings.focusDuration * 60)
            return
        }
        cycleCount = state.cycleCount
        guard let raw = state.kindRaw,
              let kind = SessionKind(rawValue: raw),
              state.remaining > 0
        else {
            phase = .idle
            remaining = Double(AppSettings.focusDuration * 60)
            return
        }
        remaining = state.remaining
        phase = state.paused ? .paused(kind) : .running(kind)
    }

    private func format(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
