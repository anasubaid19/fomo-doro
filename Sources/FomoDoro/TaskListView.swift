import SwiftUI
import SwiftData

struct TaskListView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var store: TimerStore
    @Query(sort: \TaskItem.sortOrder) private var tasks: [TaskItem]
    @State private var isAdding = false
    @State private var newTitle = ""
    @State private var newEstimate = 1

    var body: some View {
        VStack(spacing: 0) {
            if isAdding {
                VStack(spacing: 6) {
                    TextField("Task name", text: $newTitle)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(addTask)
                    HStack {
                        Stepper("Sessions: \(newEstimate)", value: $newEstimate, in: 1...20)
                        Spacer()
                        Button("Cancel") { cancelAdd() }
                        Button("Add", action: addTask)
                            .buttonStyle(.borderedProminent)
                            .disabled(newTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
            } else {
                Button {
                    isAdding = true
                    newTitle = ""
                    newEstimate = 1
                } label: {
                    Label("Add Task", systemImage: "plus")
                }
                .buttonStyle(.borderless)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

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
                if tasks.isEmpty && !isAdding {
                    ContentUnavailableView(
                        "No tasks yet",
                        systemImage: "checklist",
                        description: Text("Add a task to start tracking your focus.")
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
            context.insert(TaskItem(title: title, estimate: newEstimate, sortOrder: order))
            try? context.save()
        }
        cancelAdd()
    }

    private func cancelAdd() {
        isAdding = false
        newTitle = ""
        newEstimate = 1
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

            VStack(alignment: .leading, spacing: 1) {
                Text(task.title)
                    .strikethrough(task.isDone)
                    .foregroundStyle(task.isDone ? Color.secondary : Color.primary)
                    .lineLimit(1)
                    .help(task.title)
                if store.activeTask === task {
                    Text("Currently focusing")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            Text("🍅 \(task.completed)/\(task.estimate)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityLabel("\(task.completed) of \(task.estimate) pomodoros completed")
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
