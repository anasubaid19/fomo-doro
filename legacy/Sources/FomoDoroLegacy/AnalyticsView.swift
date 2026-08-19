import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject private var dataStore: LegacyDataStore

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    private var sessions: [FocusSession] { dataStore.sessions.sorted { $0.start > $1.start } }
    private var tasks: [TaskItem] { dataStore.tasks }
    private var today: Date { Calendar.current.startOfDay(for: Date()) }
    private var todaySessions: [FocusSession] { sessions.filter { $0.start >= today } }
    private var allFocus: [FocusSession] { sessions.filter { $0.kind == .focus } }
    private var focusToday: [FocusSession] { todaySessions.filter { $0.kind == .focus } }
    private var focusCount: Int { focusToday.count }
    private var focusMinutes: Int { focusToday.reduce(0) { $0 + $1.durationSeconds } / 60 }
    private var breakMinutes: Int {
        todaySessions.filter { $0.kind != .focus }.reduce(0) { $0 + $1.durationSeconds } / 60
    }
    private var tasksDoneToday: Int {
        tasks.filter { $0.isDone && ($0.completedAt ?? .distantPast) >= today }.count
    }
    private var allTimeSeconds: Int { allFocus.reduce(0) { $0 + $1.durationSeconds } }
    private var allTimeText: String {
        "\(allTimeSeconds / 3600)h \(allTimeSeconds % 3600 / 60)m focused"
    }
    private var last7TotalMinutes: Int { last7Days.reduce(0) { $0 + $1.minutes } }

    var body: some View {
        if sessions.isEmpty {
            LegacyEmptyState(
                title: "No sessions yet",
                systemImage: "chart.bar",
                message: "Start a timer to build your stats."
            )
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Today").font(.headline)
                    HStack(spacing: 8) {
                        StatBox(title: "Sessions", value: "\(focusCount)")
                        StatBox(title: "Focus min", value: "\(focusMinutes)")
                        StatBox(title: "Break min", value: "\(breakMinutes)")
                        StatBox(title: "Tasks done", value: "\(tasksDoneToday)")
                    }

                    dailyGoalRow

                    Text("Streak").font(.headline)
                    Text("🔥 \(streak()) days")
                        .font(.title3.bold())
                        .monospacedDigit()

                    Text("All-time").font(.headline)
                    Text(allTimeText)
                        .font(.title3.bold())
                        .monospacedDigit()

                    Text("Last 7 days").font(.headline)
                    HStack(spacing: 8) {
                        StatBox(title: "Total", value: formatMinutes(last7TotalMinutes))
                        StatBox(title: "Avg per day", value: formatMinutes(last7TotalMinutes / 7))
                    }

                    LegacyBarChart(days: last7Days)
                        .frame(height: 140)

                    Text("Session history — today").font(.headline)
                    historyList
                }
                .padding(14)
            }
        }
    }

    private var dailyGoalRow: some View {
        VStack(alignment: .leading, spacing: 4) {
            ProgressView(value: min(Double(focusCount) / Double(max(AppSettings.dailyGoal, 1)), 1.0))
                .tint(.red)
            Text("Daily goal: \(focusCount) / \(AppSettings.dailyGoal) sessions")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private var historyList: some View {
        if todaySessions.isEmpty {
            Text("No sessions yet today")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            VStack(spacing: 6) {
                ForEach(todaySessions) { session in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(session.kind.color)
                            .frame(width: 6, height: 6)
                        Text(Self.timeFormatter.string(from: session.start))
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                        Text(session.taskTitle ?? "—")
                            .font(.caption)
                            .lineLimit(1)
                            .help(session.taskTitle ?? "")
                        Spacer()
                        Text("\(session.durationSeconds / 60) min")
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var last7Days: [DayStat] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return stride(from: 6, through: 0, by: -1).map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            let next = calendar.date(byAdding: .day, value: 1, to: day)!
            let minutes = allFocus
                .filter { $0.start >= day && $0.start < next }
                .reduce(0) { $0 + $1.durationSeconds } / 60
            return DayStat(id: day, label: formatter.string(from: day), minutes: minutes)
        }
    }

    private func streak() -> Int {
        let calendar = Calendar.current
        let days = Set(allFocus.map { calendar.startOfDay(for: $0.start) })
        var count = 0
        var day = today
        if !days.contains(day) {
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        while days.contains(day) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    private func formatMinutes(_ minutes: Int) -> String {
        minutes >= 60 ? "\(minutes / 60)h \(minutes % 60)m" : "\(minutes)m"
    }
}

struct DayStat: Identifiable {
    let id: Date
    let label: String
    let minutes: Int
}

private struct LegacyBarChart: View {
    let days: [DayStat]

    private var maximum: Int { max(days.map(\.minutes).max() ?? 0, 1) }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(days) { day in
                VStack(spacing: 4) {
                    Spacer(minLength: 0)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.red)
                        .frame(height: max(2, 104 * CGFloat(day.minutes) / CGFloat(maximum)))
                    Text(day.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .help("\(day.minutes) minutes")
            }
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold())
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.08)))
    }
}
