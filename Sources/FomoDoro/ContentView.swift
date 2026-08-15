import SwiftUI
import SwiftData
import AppKit

enum Tab: Hashable {
    case tasks, notes, stats, settings
}

struct ContentView: View {
    @EnvironmentObject private var store: TimerStore
    @State private var tab: Tab = .tasks

    var body: some View {
        VStack(spacing: 0) {
            TimerHeaderView()
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

            Divider()
            HStack {
                Spacer()
                Button("Quit FomoDoro") { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(6)
        }
        .frame(width: 360)
    }
}
