import SwiftUI

struct TaskListView: View {
    @EnvironmentObject private var dataStore: LegacyDataStore
    @EnvironmentObject private var store: TimerStore
    @State private var isAdding = false
    @State private var newTitle = ""
    @State private var newEstimate = 1

    private var tasks: [TaskItem] { dataStore.tasks }

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
                    LegacyEmptyState(
                        title: "No tasks yet",
                        systemImage: "checklist",
                        message: "Add a task to start tracking your focus."
                    )
                }
            }
        }
    }

    private func addTask() {
        let title = newTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        withAnimation(.timingCurve(0.23, 1, 0.32, 1, duration: 0.2)) {
            dataStore.addTask(title: title, estimate: newEstimate)
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
            dataStore.delete(task)
        }
    }

    private func delete(at offsets: IndexSet) {
        let tasksToDelete = offsets.map { tasks[$0] }
        withAnimation(.timingCurve(0.23, 1, 0.32, 1, duration: 0.2)) {
            for task in tasksToDelete {
                if store.activeTask === task { store.activeTask = nil }
                dataStore.delete(task)
            }
        }
    }
}

struct TaskRow: View {
    @EnvironmentObject private var store: TimerStore
    @EnvironmentObject private var dataStore: LegacyDataStore
    @ObservedObject var task: TaskItem

    var body: some View {
        HStack(spacing: 8) {
            Button {
                task.isDone.toggle()
                task.completedAt = task.isDone ? Date() : nil
                dataStore.save()
            } label: {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isDone ? Color.green : Color.secondary)
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
            Button("Increase estimate") {
                task.estimate += 1
                dataStore.save()
            }
            Button("Decrease estimate") {
                if task.estimate > 1 {
                    task.estimate -= 1
                    dataStore.save()
                }
            }
        }
    }
}

struct LegacyEmptyState: View {
    let title: String
    let systemImage: String
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 30))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
