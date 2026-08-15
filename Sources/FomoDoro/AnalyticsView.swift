import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Query(sort: \FocusSession.start, order: .reverse) private var sessions: [FocusSession]
    @Query(sort: \TaskItem.sortOrder) private var tasks: [TaskItem]

    private var today: Date { Calendar.current.startOfDay(for: Date()) }

    private var todaySessions: [FocusSession] { sessions.filter { $0.start >= today } }
    private var focusToday: [FocusSession] { todaySessions.filter { $0.kind == .focus } }

    private var focusCount: Int { focusToday.count }
    private var focusMinutes: Int { focusToday.reduce(0) { $0 + $1.durationSeconds } / 60 }
    private var breakMinutes: Int {
        todaySessions.filter { $0.kind != .focus }.reduce(0) { $0 + $1.durationSeconds } / 60
    }
    private var tasksDoneToday: Int {
        tasks.filter { $0.isDone && ($0.completedAt ?? .distantPast) >= today }.count
    }
    private var totalFocusHours: Int {
        sessions.filter { $0.kind == .focus }.reduce(0) { $0 + $1.durationSeconds } / 3600
    }

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
                    HStack(spacing: 8) {
                        StatBox(title: "Focus", value: "\(focusCount)")
                        StatBox(title: "Focus min", value: "\(focusMinutes)")
                        StatBox(title: "Break min", value: "\(breakMinutes)")
                    }
                    HStack(spacing: 8) {
                        StatBox(title: "Tasks done", value: "\(tasksDoneToday)")
                        StatBox(title: "Streak", value: "\(streak()) 🔥")
                        StatBox(title: "Total focus", value: "\(totalFocusHours)h")
                    }

                    Text("Last 7 days — focus minutes")
                        .font(.headline)
                        .padding(.top, 4)

                    Chart {
                        ForEach(last7Days) { day in
                            BarMark(
                                x: .value("Day", day.label),
                                y: .value("Minutes", day.minutes)
                            )
                            .foregroundStyle(Color.red.gradient)
                        }
                    }
                    .frame(height: 160)
                }
                .padding(14)
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
            let minutes = sessions
                .filter { $0.kind == .focus && $0.start >= day && $0.start < next }
                .reduce(0) { $0 + $1.durationSeconds } / 60
            result.append(DayStat(id: day, label: formatter.string(from: day), minutes: minutes))
        }
        return result
    }

    private func streak() -> Int {
        let cal = Calendar.current
        let days = Set(sessions.filter { $0.kind == .focus }.map { cal.startOfDay(for: $0.start) })
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
