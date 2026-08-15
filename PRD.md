# Fomo-Doro — Product Requirements Document

## 1. Executive Summary

**Problem Statement**: Existing pomodoro tools are either too heavy (web/Electron apps that live in the dock) or lack analytics and task context. The author already built a GNOME Shell extension (`pomodorotimer-gnome`) and wants the same utility on macOS, living quietly in the menu bar.

**Proposed Solution**: A native macOS menu-bar app (Swift + SwiftUI `MenuBarExtra`) that combines a pomodoro timer, a flat to-do list with pomodoro estimates, and focus analytics — no dock icon, always one click away.

**Success Criteria**:
- Timer runs focus/break cycles without opening a window (menu-bar countdown visible).
- Completed focus sessions increment the active task and persist to history.
- Today / last-7-days / lifetime analytics render from real session data.
- App consumes minimal resources and shows **no dock icon** (`LSUIElement` + `.accessory`).
- Builds and launches locally without code signing.

## 2. User Experience & Functionality

**User Personas**: A solo developer who wants focused work blocks, task-level progress, and a weekly view of focus time.

**User Stories**:
- As a user, I want a countdown visible in the menu bar so I can see remaining time without switching windows.
- As a user, I want to start/pause/skip/reset sessions from a compact popover.
- As a user, I want to maintain a task list and mark the task I'm working on, so completed pomodoros auto-increment that task.
- As a user, I want a daily focus/break summary, a streak counter, and a 7-day chart.
- As a user, I want to tune durations (focus/short/long break, long-break interval), sound, and auto-start.

**Acceptance Criteria**:
- Focus defaults to 25 min, short break 5, long break 15, interval 4.
- On focus completion: session recorded, active task's `completed` +1 (and auto-marks done when `completed >= estimate`), notification + sound fired, cycle advances.
- Every 4th completed focus triggers a long break.
- Analytics correctly aggregate `FocusSession` rows by day (0 sessions = 0 minutes, no crash).
- Tasks support add, toggle-done, delete, and estimate adjust; active task is highlighted.
- Settings persist across relaunch via `UserDefaults`.

**Non-Goals**:
- No cloud sync / multi-device / accounts.
- No due dates, priorities, subtasks, or multiple project lists.
- No App Store distribution or code signing.
- No persistence of an in-progress timer across app relaunch.

## 3. AI System Requirements

None. No AI/ML components.

## 4. Technical Specifications

**Architecture**: Single SwiftPM executable target. `@main` SwiftUI `App` hosts a `MenuBarExtra` (`.window` style). A `@MainActor` `TimerStore` (`ObservableObject`) owns the phase state machine and a 1 Hz tick loop (`Task.sleep`). SwiftData (`ModelContainer`) persists `TaskItem` and `FocusSession`. Analytics is computed in-view from `@Query` results. Settings live in `UserDefaults`.

**Components**:
- `FomoDoroApp` — app entry, model container, `.accessory` activation policy.
- `TimerStore` — phases (idle/running/paused × focus/shortBreak/longBreak), tick, completion recording, notification + `NSSound`.
- `Models` — `TaskItem` (title, estimate, completed, isDone, completedAt, sortOrder), `FocusSession` (kind, start, durationSeconds, taskTitle).
- `AppSettings` — typed `UserDefaults` access with registered defaults.
- Views — `ContentView` (segmented nav), `TimerHeaderView` + `TimerRingView`, `TaskListView`, `AnalyticsView`, `SettingsView`.

**Integration Points**: System frameworks only — SwiftUI, SwiftData, Swift Charts, AppKit (`NSSound`, `NSApplication`), UserNotifications. No third-party dependencies.

**Security & Privacy**: All data stored locally in the app's SwiftData store (`~/Library/Application Support`). No network access. Notifications require standard user consent.

## 5. Risks & Roadmap

**Phased Rollout**:
- **MVP (this build)**: timer + tasks + today/7-day analytics + settings + menu-bar bundle.
- **v1.1**: task estimate editing UI inline, export analytics (CSV).
- **v2.0**: weekly/monthly rollups, idle-detection pause, iCloud sync (opt-in).

**Technical Risks**:
- Menu-bar `MenuBarExtra` `.window` style has limited interaction (no global hotkeys) — acceptable for MVP.
- `Task.sleep` tick drifts ~sub-second per session — negligible for pomodoro timing.

**Build & Run**:
```sh
swift run                                   # dev (menu bar app, no dock icon)
./scripts/build-app.sh                      # produces FomoDoro.app (double-clickable)
```
