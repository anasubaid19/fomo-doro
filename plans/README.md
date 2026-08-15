# Animation Plans

Recommended execution order: `001` before `002` (independent, but 001 touches the shared `TimerStore`/ring code and is the higher-severity fix; do it first).

| # | Title | Severity | Status |
|---|-------|----------|--------|
| 001 | Smooth continuous countdown ring (stutter + reset rewind + reduced-motion) | MEDIUM | DONE |
| 002 | Animate task list insert/delete and checkmark toggle | LOW | DONE |

## Dependencies

- 001: none.
- 002: none (different file from 001; can be executed in parallel or independently).

## How to execute

From the repo root:

```
improve-animations execute plans/001-smooth-countdown-ring.md
improve-animations execute plans/002-task-list-transitions.md
```

Or hand either file to any agent — each plan is self-contained (exact file paths, current code, target code, and verification steps).

## Not planned (deferred)

- **Finding #5** — phase color/label crossfade (`TimerRingView` red↔green snap). Deferred; low value vs. risk of touching the ring again.
- **Missed opportunity** — completion celebration pulse; omitted to preserve the utility app's restrained personality.
- **Missed opportunity** — active-task `play.fill` indicator fade-in; trivial, revisit with #5.
