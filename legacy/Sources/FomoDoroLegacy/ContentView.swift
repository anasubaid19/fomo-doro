import SwiftUI

enum Tab: Hashable {
    case tasks, notes, stats, settings
}

struct ContentView: View {
    @EnvironmentObject private var store: TimerStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var tab: Tab = .tasks

    var body: some View {
        VStack(spacing: 0) {
            TimerHeaderView(compact: tab != .tasks)
            Divider()
            Picker("", selection: tabBinding) {
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
            .id(tab)
            .transition(.opacity)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 360, height: 651)
        .onAppear {
            store.retryNotificationPermissionIfNeeded()
        }
    }

    // ponytail: fixed popover height (651) keeps the window size constant so tab
    // switches morph internally instead of resizing the NSPopover frame per animation.
    private var tabBinding: Binding<Tab> {
        Binding(
            get: { tab },
            set: { newTab in
                guard newTab != tab else { return }
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.15)) {
                    tab = newTab
                }
            }
        )
    }
}
