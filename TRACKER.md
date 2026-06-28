# 🛰️ Pixel Dweller — Live Tracker

**This file is the single source of truth.** Humans read it to watch progress.
Agents read it to know what to do next and to resume after a session/token reset.

> To resume in a new session: *"Read TRACKER.md and continue the autonomous build."*

## Control panel (edit these to steer the loop)

```yaml
paused: false            # set true to halt the cron loop immediately
max_tasks_per_day: 8     # cron stops after this many merged tasks/day
default_worker: opencode/big-pickle   # primary codegen model
escalation_worker: hermes/grok        # used after 2 failed attempts
reviewer: claude         # only Claude reviews/merges
retry_cap: 2             # attempts before escalating model
date: 2026-06-28
tasks_merged_today: 5
```

## Legend
`todo` → `in_progress` → `in_review` (PR open, CI green, awaiting Claude) →
`done` (merged + shipped) · `blocked` (needs human) · `failed` (retrying)

## Task board

| ID | Phase | Title | Status | Worker | PR | Attempts | Notes |
|----|-------|-------|--------|--------|----|---------:|-------|
| P0-1 | 0 | Godot project skeleton | done | — | — | 0 | boots empty Main.tscn |
| P0-2 | 0 | GUT test framework | done | — | — | 0 | one passing test |
| P0-3 | 0 | CI workflow | done | — | — | 0 | tests+export+preview |
| P0-4 | 0 | Deploy workflow | done | — | — | 0 | Pages on main |
| P0-5 | 0 | Driver + cron dry-run | done | — | — | 0 | loop picks next task |
| P1-1 | 1 | Player movement (touch+keys) | done | — | — | 0 | depends P0 |
| P1-2 | 1 | World + collision + camera | done | — | — | 0 | depends P1-1 |
| P1-3 | 1 | Needs + real-time decay | done | — | — | 0 | pure logic |
| P1-4 | 1 | Save/load + elapsed time | done | — | — | 0 | IndexedDB on web |
| P1-5 | 1 | Care actions + UI | done | — | — | 0 | bars + buttons |
| P1-6 | 1 | Life stages + growth | todo | — | — | 0 | Baby→Kid→Adult |
| P1-7 | 1 | World-change on growth | todo | — | — | 0 | the novelty seed |
| P1-8 | 1 | Polish + first ship | todo | — | — | 0 | title+settings+credits |

## Activity log (newest first — agents append one line per action)
- 2026-06-28 23:14:32 — P1-5 → done — worker big-pickle; care UI (bars+Eat/Rest/Play), decay+save wired; lead fixed Variant-inference in UI.gd + SaveManager.gd
- 2026-06-28 23:02:49 — P1-4 → done — worker big-pickle; SaveManager+TimeManager, offline-decay timestamp; 5 tests
- 2026-06-28 22:58:09 — P1-3 → done — worker big-pickle; Dweller pure-logic needs+decay; 6 tests
- 2026-06-28 22:54:49 — P1-2 → done — worker big-pickle; walkable room+camera; lead added visible placeholder sprite; player wired into Main
- 2026-06-28 22:46:59 — P1-1 → done (att 1) PR#3 — worker big-pickle; lead fixed sprite_frames + added scene test; merged+shipped

- 2026-06-28 — tracker created; harness being stood up by lead (Claude).

## Live URL

_(filled after P0-4 + first deploy)_ → https://pratyu2364-prime.github.io/pixel-dweller/
