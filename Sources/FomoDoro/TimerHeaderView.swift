import SwiftUI

struct TimerHeaderView: View {
    @EnvironmentObject private var store: TimerStore

    private var progress: Double {
        let total = store.totalForCurrentPhase
        guard total > 0 else { return 0 }
        return min(1, max(0, store.remaining / Double(total)))
    }

    private var cycleDots: Int { store.cycleCount % AppSettings.longBreakInterval }

    var body: some View {
        VStack(spacing: 12) {
            TimerRingView(progress: progress, remaining: store.displaySeconds, kind: store.currentKind)

            HStack(spacing: 6) {
                ForEach(0..<AppSettings.longBreakInterval, id: \.self) { i in
                    Circle()
                        .fill(i < cycleDots ? Color.red : Color.secondary.opacity(0.2))
                        .frame(width: 8, height: 8)
                }
            }

            if let task = store.activeTask {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill").font(.caption2).foregroundStyle(.blue)
                    Text(task.title).font(.caption).lineLimit(1)
                }
            } else {
                Text("No active task").font(.caption).foregroundStyle(.secondary)
            }

            HStack(spacing: 18) {
                Button {
                    store.togglePause()
                } label: {
                    Image(systemName: store.isRunning ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .padding(4)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(store.isRunning ? "Pause" : "Start focus")

                Button {
                    store.skip()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .padding(4)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Skip to next session")

                Button {
                    store.reset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title2)
                        .padding(4)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Reset timer")
            }
            .padding(.bottom, 4)
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }
}

struct TimerRingView: View {
    let progress: Double
    let remaining: Int
    let kind: SessionKind?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var color: Color {
        switch kind {
        case .shortBreak, .longBreak: return .green
        default: return .red
        }
    }

    private var label: String {
        switch kind {
        case .focus: return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        case nil: return "Focus"
        }
    }

    var body: some View {
        ZStack {
            Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 10)
            Circle()
                .trim(from: 0, to: reduceMotion ? 1 : max(0, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 2) {
                Text(timeString)
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 150, height: 150)
    }

    private var timeString: String {
        String(format: "%02d:%02d", remaining / 60, remaining % 60)
    }
}
