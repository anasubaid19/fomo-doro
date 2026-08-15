# FomoDoro 🍅

A native macOS menu bar pomodoro timer with task tracking and focus analytics. Successor to [pomodorotimer-gnome](https://github.com/anasubaid19/pomodorotimer-gnome).

## Features

- **Menu bar countdown** — live timer in the menu bar, no dock icon
- **Pomodoro timer** — focus / short break / long break, configurable durations and long-break interval
- **Cycle dots** — track your position in the 4-pomodoro cycle
- **Next button** — mark the current phase done and jump to the next phase (advances the cycle)
- **Survives restarts** — timer phase and cycle position are restored after quit/relaunch
- **Tasks** — to-do list with pomodoro estimates; completed sessions auto-increment the active task
- **Analytics** — today's focus/break minutes, streak, last-7-days chart, lifetime totals
- **Notifications & sound** — on session completion, with a sound picker (system presets or your own audio file)
- **Update notifications** — tells you when a new release is on GitHub
- **Quick note** — scratchpad tab for jotting things down
- **Launch at login** — optional
- **Settings** — durations, long-break interval, sound, auto-start next session

## Install

Get the latest `FomoDoro.dmg` from [Releases](https://github.com/anasubaid19/fomo-doro/releases), then pick one of the options below.

> FomoDoro is a **menu bar app** — after it starts there is no window and no dock icon.
> Look for the 🍅 in the top-right menu bar and click it.

> Why Gatekeeper warnings at all? The app is not signed/notarized (that requires a
> paid Apple Developer certificate), so macOS flags downloaded copies. All three
> options below get you a working install.

### Option A — Drag & drop (GUI)

1. Open `FomoDoro.dmg`, drag **FomoDoro** to **Applications**.
2. First launch only: in Applications, **right-click FomoDoro → Open**, then click **Open** in the dialog. (Don't double-click — the first time, macOS needs the explicit confirmation.)
3. Click the 🍅 in your menu bar. Later launches: just double-click.

### Option B — Terminal, no warnings at all

Removes the Gatekeeper quarantine flag so it opens cleanly like a signed app:

```sh
# after dragging FomoDoro from the dmg to Applications:
xattr -dr com.apple.quarantine /Applications/FomoDoro.app
open /Applications/FomoDoro.app
```

### Option C — Build from source

Requirements: macOS 14+ with Xcode (Swift 6).

```sh
git clone https://github.com/anasubaid19/fomo-doro.git
cd fomo-doro
swift run                     # run in dev (no notifications in dev mode)
# or build a bundle:
./scripts/build-app.sh        # builds FomoDoro.app
open FomoDoro.app
```

## Roadmap

- Export analytics to CSV
- iCloud sync
- Auto-update via Sparkle (needs Apple Developer ID)

## License

MIT — see [LICENSE](LICENSE).
