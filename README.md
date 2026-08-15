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
- **Notifications & sound** — on session completion
- **Update notifications** — tells you when a new release is on GitHub
- **Quick note** — scratchpad tab for jotting things down
- **Launch at login** — optional
- **Settings** — durations, long-break interval, sound, auto-start next session

## Download & Install

Get the latest `FomoDoro.dmg` from [Releases](https://github.com/anasubaid19/fomo-doro/releases):

1. Open the DMG, drag **FomoDoro** to **Applications**.
2. First launch: right-click the app → **Open** (the app is not signed/notarized, so Gatekeeper needs this once).
3. Click the 🍅 in your menu bar.

> Without an Apple Developer certificate the app cannot be notarized; macOS shows
> "Apple cannot check it for malicious software" for downloaded apps. Right-click → Open
> resolves it permanently for that copy.

## Build from source

Requirements: macOS 14+ with Xcode (Swift 6).

```sh
swift run                     # run in dev (no notifications in dev mode)
./scripts/build-app.sh        # builds FomoDoro.app
./scripts/make-dmg.sh         # packages FomoDoro.dmg
```

## Roadmap

- Export analytics to CSV
- iCloud sync
- Auto-update via Sparkle (needs Apple Developer ID)

## License

MIT — see [LICENSE](LICENSE).
