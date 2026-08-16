import SwiftUI

extension SessionKind {
    var displayName: String {
        switch self {
        case .focus: return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }

    var color: Color {
        switch self {
        case .shortBreak, .longBreak: return .green
        case .focus: return .red
        }
    }
}

struct TimerHeaderView: View {
    @EnvironmentObject private var store: TimerStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let compact: Bool

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if compact {
                    compactHeader
                } else {
                    expandedHeader
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: compact)

            if store.justCompletedFocus != nil {
                completionBanner
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: store.justCompletedFocus != nil)
            }
        }
    }

    // MARK: Completion banner

    private var completionBanner: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Focus complete 🎉")
                .font(.caption.weight(.semibold))
            HStack {
                if let completed = store.justCompletedFocus, let task = completed.taskTitle {
                    Text("\(task) — \(completed.durationSeconds / 60) min focused")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                if store.currentKind == nil {
                    Button("Start Break") {
                        store.startBreak(.shortBreak)
                        store.dismissCompletionBanner()
                    }
                    .controlSize(.small)
                }
                Button("Done") {
                    store.dismissCompletionBanner()
                }
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color.red.opacity(0.08))
    }

    // MARK: Compact

    private var compactHeader: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(store.currentKind?.color ?? Color.red)
                .frame(width: 8, height: 8)
            Text(store.currentKind?.displayName ?? "Focus")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(store.timeText)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
            Button {
                store.togglePause()
            } label: {
                Image(systemName: store.isRunning ? "pause.fill" : "play.fill")
                    .padding(4)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(store.isRunning ? "Pause" : "Start focus")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: Expanded

    private var progress: Double {
        let total = store.totalForCurrentPhase
        guard total > 0 else { return 0 }
        return min(1, max(0, store.remaining / Double(total)))
    }

    private var cycleDots: Int { store.cycleCount % AppSettings.longBreakInterval }

    private var expandedHeader: some View {
        VStack(spacing: 10) {
            TimerRingView(progress: progress, remaining: store.displaySeconds, kind: store.currentKind)

            HStack(spacing: 6) {
                ForEach(0..<AppSettings.longBreakInterval, id: \.self) { i in
                    Circle()
                        .fill(i < cycleDots ? Color.red : Color.secondary.opacity(0.2))
                        .frame(width: 8, height: 8)
                }
                Text("\(cycleDots) of \(AppSettings.longBreakInterval)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .help("Pomodoro \(cycleDots) of \(AppSettings.longBreakInterval) before long break")

            if let task = store.activeTask {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill").font(.caption2).foregroundStyle(.blue)
                    Text(task.title).font(.caption).lineLimit(1).help(task.title)
                }
            } else {
                Text("No active task").font(.caption).foregroundStyle(.secondary)
            }

            HStack(spacing: 18) {
                Button {
                    store.togglePause()
                } label: {
                    Image(systemName: store.isRunning ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .padding(4)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(store.isRunning ? "Pause" : "Start focus")

                Button {
                    store.skip()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                        .padding(4)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Skip to next session")

                Button {
                    store.reset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title3)
                        .padding(4)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Reset timer")
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }
}

struct TimerRingView: View {
    let progress: Double
    let remaining: Int
    let kind: SessionKind?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 8)
            Circle()
                .trim(from: 0, to: reduceMotion ? 1 : max(0, min(1, progress)))
                .stroke(kind?.color ?? Color.red, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text(timeString)
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text(kind?.displayName ?? "Focus")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 120, height: 120)
    }

    private var timeString: String {
        String(format: "%02d:%02d", remaining / 60, remaining % 60)
    }
}
