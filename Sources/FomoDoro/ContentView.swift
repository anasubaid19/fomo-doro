import SwiftUI
import SwiftData

enum Tab: Hashable {
    case tasks, notes, stats, settings
}

struct ContentView: View {
    @EnvironmentObject private var store: TimerStore
    @State private var tab: Tab = .tasks

    var body: some View {
        VStack(spacing: 0) {
            TimerHeaderView(compact: tab != .tasks)
            Divider()
            Picker("", selection: $tab) {
                Text("Tasks").tag(Tab.tasks)
                Text("Notes").tag(Tab.notes)
                Text("Stats").tag(Tab.stats)
                Text("Settings").tag(Tab.settings)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(8)

            Group {
                switch tab {
                case .tasks: TaskListView()
                case .notes: NotesView()
                case .stats: AnalyticsView()
                case .settings: SettingsView()
                }
            }
            .frame(width: 360, height: 380)
        }
        .frame(width: 360)
        .onAppear {
            store.retryNotificationPermissionIfNeeded()
        }
    }
}
