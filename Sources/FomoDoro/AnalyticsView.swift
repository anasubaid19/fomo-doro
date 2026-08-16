import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Query(sort: \FocusSession.start, order: .reverse) private var sessions: [FocusSession]
    @Query(sort: \TaskItem.sortOrder) private var tasks: [TaskItem]

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

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
            ContentUnavailableView(
                "No sessions yet",
                systemImage: "chart.bar",
                description: Text("Start a timer to build your stats.")
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

                    Chart {
                        ForEach(last7Days) { day in
                            BarMark(
                                x: .value("Day", day.label),
                                y: .value("Minutes", day.minutes)
                            )
                            .foregroundStyle(Color.red.gradient)
                        }
                    }
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
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        var result: [DayStat] = []
        for i in stride(from: 6, through: 0, by: -1) {
            let day = cal.date(byAdding: .day, value: -i, to: today)!
            let next = cal.date(byAdding: .day, value: 1, to: day)!
            let minutes = allFocus
                .filter { $0.start >= day && $0.start < next }
                .reduce(0) { $0 + $1.durationSeconds } / 60
            result.append(DayStat(id: day, label: formatter.string(from: day), minutes: minutes))
        }
        return result
    }

    private func streak() -> Int {
        let cal = Calendar.current
        let days = Set(allFocus.map { cal.startOfDay(for: $0.start) })
        var streak = 0
        var day = today
        if !days.contains(day) {
            day = cal.date(byAdding: .day, value: -1, to: day)!
        }
        while days.contains(day) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
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
