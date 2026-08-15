import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var store: TimerStore
    @Query(sort: \TaskItem.sortOrder) private var tasks: [TaskItem]
    @State private var newTitle = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                TextField("Add a task…", text: $newTitle)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addTask)
                Button(action: addTask) {
                    Image(systemName: "plus.circle.fill").font(.title3)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Add task")
                .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)

            List {
                ForEach(tasks) { task in
                    TaskRow(task: task)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            store.activeTask = (store.activeTask === task) ? nil : task
                        }
                        .accessibilityAction {
                            store.activeTask = (store.activeTask === task) ? nil : task
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                delete(task)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                .onDelete(perform: delete)
            }
            .listStyle(.inset)
            .overlay {
                if tasks.isEmpty {
                    ContentUnavailableView(
                        "No tasks yet",
                        systemImage: "checklist",
                        description: Text("Add a task to track your pomodoros.")
                    )
                }
            }
        }
    }

    private func addTask() {
        let title = newTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        let order = (tasks.map(\.sortOrder).max() ?? 0) + 1
        withAnimation(.timingCurve(0.23, 1, 0.32, 1, duration: 0.2)) {
            context.insert(TaskItem(title: title, estimate: 1, sortOrder: order))
            try? context.save()
        }
        newTitle = ""
    }

    private func delete(_ task: TaskItem) {
        withAnimation(.timingCurve(0.23, 1, 0.32, 1, duration: 0.2)) {
            if store.activeTask === task { store.activeTask = nil }
            context.delete(task)
            try? context.save()
        }
    }

    private func delete(at offsets: IndexSet) {
        withAnimation(.timingCurve(0.23, 1, 0.32, 1, duration: 0.2)) {
            for index in offsets {
                let task = tasks[index]
                if store.activeTask === task { store.activeTask = nil }
                context.delete(task)
            }
            try? context.save()
        }
    }
}

struct TaskRow: View {
    @EnvironmentObject private var store: TimerStore
    let task: TaskItem

    var body: some View {
        HStack(spacing: 8) {
            Button {
                task.isDone.toggle()
                task.completedAt = task.isDone ? Date() : nil
            } label: {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isDone ? Color.green : Color.secondary)
                    .symbolEffect(.bounce, value: task.isDone)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(task.isDone ? "Mark not done" : "Mark done")

            Text(task.title)
                .strikethrough(task.isDone)
                .foregroundStyle(task.isDone ? Color.secondary : Color.primary)
                .lineLimit(1)
                .help(task.title)

            Spacer()

            Text("🍅 \(task.completed)/\(task.estimate)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityLabel("\(task.completed) of \(task.estimate) pomodoros completed")

            if store.activeTask === task {
                Image(systemName: "play.fill")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button(store.activeTask === task ? "Remove as active task" : "Set as active task") {
                store.activeTask = (store.activeTask === task) ? nil : task
            }
            Button("Increase estimate") { task.estimate += 1 }
            Button("Decrease estimate") { if task.estimate > 1 { task.estimate -= 1 } }
        }
    }
}
