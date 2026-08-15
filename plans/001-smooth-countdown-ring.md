# 001 — Smooth continuous countdown ring (fix stutter, reset rewind, reduced-motion)

- **Status**: DONE
- **Commit**: n/a (not a git repo)
- **Severity**: MEDIUM (merged: findings #1 stutter, #2 reset rewind, #3 reduced-motion)
- **Category**: Easing & duration / Physicality / Accessibility
- **Estimated scope**: 2 files (`TimerStore.swift`, `TimerHeaderView.swift`)

## Problem

The countdown ring is the app's only motion element and it is wrong three ways.

1. **Stutter.** `remaining` is an `Int` decremented once per second, and the ring animates each discrete step over half a second, then freezes for the other half — stop-motion instead of a continuous sweep.

2. **Reset rewind.** When a session completes and the next starts, `remaining` jumps from `0` to the full duration, so `progress` jumps `0 → 1` and the `.animation` sweeps the ring from empty back to full over 0.5s. A new session should present an already-full ring, not rewind into it.

3. **No reduced-motion handling.** The ring sweeps constantly while the popover is open; `prefers-reduced-motion` is ignored.

Current code, `Sources/FomoDoro/TimerHeaderView.swift`:

```swift
// TimerHeaderView.swift:6 — current
private var progress: Double {
    let total = store.totalForCurrentPhase
    guard total > 0 else { return 0 }
    return Double(store.remaining) / Double(total)
}
```

```swift
// TimerHeaderView.swift:79-83 — current
Circle()
    .trim(from: 0, to: max(0, min(1, progress)))
    .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
    .rotationEffect(.degrees(-90))
    .animation(.linear(duration: 0.5), value: progress)
```

Current code, `Sources/FomoDoro/TimerStore.swift`:

```swift
// TimerStore.swift:15 — current
@Published var remaining: Int = 0
```

```swift
// TimerStore.swift:45-50 — current
var menuBarText: String {
    switch phase {
    case .idle: return "🍅"
    case .running, .paused: return (isRunning ? "🍅 " : "⏸ ") + format(remaining)
    }
}
```

```swift
// TimerStore.swift:60-73 — current
func resetToIdle() {
    phase = .idle
    remaining = AppSettings.focusDuration * 60
}

func startFocus() {
    remaining = AppSettings.focusDuration * 60
    phase = .running(.focus)
}

func startBreak(_ kind: SessionKind) {
    remaining = duration(for: kind) * 60
    phase = .running(kind)
}
```

```swift
// TimerStore.swift:93-108 — current
private func startTickLoop() {
    tickTask = Task { @MainActor [weak self] in
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(1))
            self?.tick()
        }
    }
}

private func tick() {
    guard isRunning else { return }
    remaining -= 1
    if remaining <= 0 {
        completeSession(interrupted: false)
    }
}
```

## Target

The fix is to make `remaining` a continuous `Double`, tick at 10 Hz, and **delete** the `.animation` modifier. With no animation modifier there is nothing to rewind on reset (fixes #2) and no half-second freeze (fixes #1). Reduced motion is handled by rendering a static full ring while the number still counts down (fixes #3).

`Sources/FomoDoro/TimerStore.swift`:

```swift
// TimerStore.swift:15 — target
@Published var remaining: Double = 0

// add a display-seconds accessor (next to the other computed vars)
var displaySeconds: Int { max(0, Int(remaining.rounded(.up))) }
```

```swift
// TimerStore.swift:45-50 — target
var menuBarText: String {
    switch phase {
    case .idle: return "🍅"
    case .running, .paused: return (isRunning ? "🍅 " : "⏸ ") + format(displaySeconds)
    }
}
```

```swift
// TimerStore.swift:60-73 — target
func resetToIdle() {
    phase = .idle
    remaining = Double(AppSettings.focusDuration * 60)
}

func startFocus() {
    remaining = Double(AppSettings.focusDuration * 60)
    phase = .running(.focus)
}

func startBreak(_ kind: SessionKind) {
    remaining = Double(duration(for: kind) * 60)
    phase = .running(kind)
}
```

```swift
// TimerStore.swift:93-108 — target
private func startTickLoop() {
    tickTask = Task { @MainActor [weak self] in
        while !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(100))
            self?.tick()
        }
    }
}

private func tick() {
    guard isRunning else { return }
    // ponytail: 0.1s decrement accumulates negligible float error over a 25-min
    // session; switch to a wall-clock endDate if sub-second accuracy ever matters.
    remaining -= 0.1
    if remaining <= 0 {
        completeSession(interrupted: false)
    }
}
```

`Sources/FomoDoro/TimerHeaderView.swift`:

```swift
// TimerHeaderView.swift:6-10 — target
private var progress: Double {
    let total = store.totalForCurrentPhase
    guard total > 0 else { return 0 }
    return min(1, max(0, store.remaining / Double(total)))
}
```

```swift
// TimerHeaderView.swift:14 — target (pass displaySeconds, not the raw Double)
TimerRingView(progress: progress, remaining: store.displaySeconds, kind: store.currentKind)
```

```swift
// TimerHeaderView.swift:55-83 — target
struct TimerRingView: View {
    let progress: Double
    let remaining: Int
    let kind: SessionKind?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // ... color / label computed vars unchanged ...

    var body: some View {
        ZStack {
            Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 10)
            Circle()
                .trim(from: 0, to: reduceMotion ? 1 : max(0, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
            // .animation(...) removed entirely
            VStack(spacing: 2) { ... }
        }
        .frame(width: 150, height: 150)
    }
}
```

The `timeString` computed property (`String(format: "%02d:%02d", remaining / 60, remaining % 60)`) is unchanged — it still receives an `Int` via the `remaining:` parameter (now `store.displaySeconds`).

## Repo conventions to follow

- This is a SwiftUI/AppKit app; all system frameworks, no third-party motion libraries.
- State lives in the `@MainActor TimerStore` (an `ObservableObject`); views are read-only consumers via `@EnvironmentObject`. Keep it that way — do not introduce a separate animation model.
- Existing `ponytail:` comments document deliberate simplifications; continue that style.

## Steps

1. In `TimerStore.swift`, change `remaining` to `Double` (line 15) and add the `displaySeconds` computed property near the other computed vars (`menuBarText`, `isRunning`).
2. In `TimerStore.swift`, update `menuBarText`, `resetToIdle`, `startFocus`, and `startBreak` to use `Double(...)` and `displaySeconds` exactly as in Target.
3. In `TimerStore.swift`, change `startTickLoop` sleep to `.milliseconds(100)` and `tick` to `remaining -= 0.1`.
4. In `TimerHeaderView.swift`, update `progress` (line 6-10) and the `TimerRingView` call (line 14) to use `store.displaySeconds`.
5. In `TimerHeaderView.swift`, add `@Environment(\.accessibilityReduceMotion) private var reduceMotion` to `TimerRingView`, change the trim `to:` to `reduceMotion ? 1 : max(0, min(1, progress))`, and delete the `.animation(.linear(duration: 0.5), value: progress)` line.
6. Run the build (see Verification). Do not touch any other file.

## Boundaries

- Do NOT touch `TaskListView.swift`, `AnalyticsView.swift`, `SettingsView.swift`, `ContentView.swift`, or `Models.swift`.
- Do NOT change `totalForCurrentPhase`, `duration(for:)`, `completeSession`, `advanceAfterCompletion`, or the notification/sound code.
- Do NOT add dependencies or frameworks.
- Do NOT change the ring geometry (frame, line widths, colors) — motion logic only.
- If any cited line does not match what you find, STOP and report instead of improvising.

## Verification

- **Mechanical**: `swift build` — must succeed with no new warnings.
- **Feel check** (run `swift run`):
  - Open the popover, press play: the ring drains **smoothly and continuously** — no visible 0.5s freeze/pulse each second.
  - Watch the numeric countdown: it still ticks once per second, `25:00 → 24:59 → …`, never showing `00:00` early.
  - Let a short session finish (set focus to 1 min in Settings): the next ring appears **already full** — no rewind sweep from empty to full.
  - Toggle `System Settings → Accessibility → Display → Reduce Motion` on, reopen the popover, play: the ring stays a **static full circle** while the number still counts down.
  - Pause/resume and skip/reset repeatedly: `remaining` never goes negative, no crash, no NaN.
- **Done when**: build passes AND all four feel-check bullets hold.

(Reduced-motion behavior: a static ring still communicates "session active" while the number carries the progress; this matches the playbook's "keep opacity/color, drop movement".)
