# 002 — Animate task list insert/delete and checkmark toggle

- **Status**: DONE
- **Commit**: n/a (not a git repo)
- **Severity**: LOW
- **Category**: Missed opportunities
- **Estimated scope**: 1 file (`TaskListView.swift`)

## Problem

Task rows teleport in and out: adding a task or deleting one swaps the list instantly with no transition, and toggling the done-checkbox changes state with no feedback. These are occasional actions (add/delete/toggle-done), so standard animation is appropriate — not the constant list-hover motion the playbook forbids.

Current code, `Sources/FomoDoro/TaskListView.swift`:

```swift
// TaskListView.swift:42-49 — current
private func addTask() {
    let title = newTitle.trimmingCharacters(in: .whitespaces)
    guard !title.isEmpty else { return }
    let order = (tasks.map(\.sortOrder).max() ?? 0) + 1
    context.insert(TaskItem(title: title, estimate: 1, sortOrder: order))
    try? context.save()
    newTitle = ""
}
```

```swift
// TaskListView.swift:51-58 — current
private func delete(at offsets: IndexSet) {
    for index in offsets {
        let task = tasks[index]
        if store.activeTask === task { store.activeTask = nil }
        context.delete(task)
    }
    try? context.save()
}
```

```swift
// TaskListView.swift:56-63 — current (inside TaskRow)
Button {
    task.isDone.toggle()
    task.completedAt = task.isDone ? Date() : nil
} label: {
    Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
        .foregroundStyle(task.isDone ? Color.green : Color.secondary)
}
.buttonStyle(.borderless)
```

## Target

Wrap the SwiftData mutations in a `withAnimation` using a strong ease-out curve (matches the playbook's `--ease-out: cubic-bezier(0.23, 1, 0.32, 1)`), and add a `symbolEffect(.bounce)` on the checkmark so the toggle gives tactile feedback.

`Sources/FomoDoro/TaskListView.swift`:

```swift
// TaskListView.swift:42-49 — target
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
```

```swift
// TaskListView.swift:51-58 — target
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
```

```swift
// TaskListView.swift:56-63 — target
Button {
    task.isDone.toggle()
    task.completedAt = task.isDone ? Date() : nil
} label: {
    Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
        .foregroundStyle(task.isDone ? Color.green : Color.secondary)
        .symbolEffect(.bounce, value: task.isDone)
}
.buttonStyle(.borderless)
```

## Repo conventions to follow

- Views read state via `@EnvironmentObject store` and `@Environment(\.modelContext)`; all mutations go through `context` and `try? context.save()`. Preserve that.
- No third-party motion libraries; use SwiftUI built-ins only.

## Steps

1. In `TaskListView.swift`, wrap the body of `addTask` (the `context.insert` + `try? context.save()`) in `withAnimation(.timingCurve(0.23, 1, 0.32, 1, duration: 0.2)) { ... }` exactly as in Target.
2. In `TaskListView.swift`, wrap the body of `delete` (the for-loop + save) in the same `withAnimation`.
3. In `TaskListView.swift`, add `.symbolEffect(.bounce, value: task.isDone)` to the checkmark `Image` inside `TaskRow`.
4. Run the build (see Verification). Do not touch any other file.

## Boundaries

- Do NOT touch `TimerStore.swift`, `TimerHeaderView.swift`, `AnalyticsView.swift`, `SettingsView.swift`, or `Models.swift`.
- Do NOT restructure the row layout or change any text/style beyond the additions above.
- Do NOT add reduced-motion handling here — that is covered by plan 001 for the ring only.
- Do NOT add dependencies.
- If a cited line does not match what you find, STOP and report instead of improvising.

## Verification

- **Mechanical**: `swift build` — must succeed with no new warnings.
- **Feel check** (run `swift run`):
  - Add a task: the new row slides/fades in smoothly (~0.2s), the list does not jump.
  - Delete a task (swipe or via delete): the row animates out, remaining rows collapse smoothly.
  - Toggle a task's checkbox repeatedly: the checkmark gives a quick bounce each time; spam toggling never freezes or desyncs the strikethrough state.
- **Done when**: build passes AND add/delete/toggle all animate without list jumps.

(`symbolEffect(.bounce)` uses the system's spring; its exact curve is a SwiftUI built-in — do not hand-tune it.)
