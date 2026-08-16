# Changelog

All notable changes to FomoDoro.

## [1.3.0] - 2026-08-15

### Added

- Compact timer header on Notes/Stats/Settings tabs (expanded timer stays on Tasks) with smooth transition
- Cycle dots now show "2 of 4" plus a tooltip before the long break
- "Show countdown in menu bar" setting

### Changed

- Smaller, tighter expanded timer (ring reduced ~20%)
- Quit moved from the footer into Settings → About; footer removed
- Settings tab scrolls instead of clipping

## [1.2.1] - 2026-08-15

### Fixed

- Crash on launch on macOS 26 for the GitHub-release build (built with an older SDK); releases now build on a macOS 26 runner and notification permission is requested after launch

## [1.2.0] - 2026-08-15

### Added

- Completion sound picker: choose from system presets (Glass, Ping, Pop, Submarine, Basso, Funk), none, or your own audio file with preview

## [1.1.0] - 2026-08-15

### Added

- Quick note tab (autosaved scratchpad)
- Launch at login setting
- Update checker: notifies when a new GitHub release is available

## [1.0.0] - 2026-08-15

- Initial release: pomodoro timer, tasks with pomodoro estimates, analytics (today/streak/7-day chart), cycle dots, timer state persistence
