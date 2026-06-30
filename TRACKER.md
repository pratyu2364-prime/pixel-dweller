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
tasks_merged_today: 8
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
| P1-6 | 1 | Life stages + growth | done | — | — | 0 | Baby→Kid→Adult |
| P1-7 | 1 | World-change on growth | done | — | — | 0 | the novelty seed |
| P1-8 | 1 | Polish + first ship | done | — | — | 0 | title+settings+credits |
| P2-1 | 2 | Area framework + dynamic loading | done | big-pickle | #13 | 1 | House loaded via AreaManager; saves current_area |
| P2-2 | 2 | Door transitions + Garden | done | big-pickle | #14 | 1 | walk-into-door + fade; House↔Garden |
| P2-3 | 2 | Growth decor → Garden | done | big-pickle | #15 | 1 | per-area novelty; House clean |
| P2-4 | 2 | Town area + door | done | big-pickle | #16 | 1 | 3 areas reachable on foot |
| P2-5 | 2 | Town NPC greeting | done | big-pickle | #17 | 1 | dialog + cooldown mood boost |
| P2-6 | 2 | Phase 2 polish + ship | todo | — | — | 0 | area label; full tour; ship |

## Activity log (newest first — agents append one line per action)
- 2026-07-01 — P2-5 → done (att 1) PR#17 — worker big-pickle; Town NPC greeting (dialog + cooldown mood boost); interact action (E/Space) + touch Talk button; greet() pure cooldown logic; 69 tests; +10 mood once then cooldown verified headless
- 2026-07-01 — P2-4 → done (att 1) PR#16 — worker big-pickle; Town area (distinct) + Garden↔Town doors; House↔Garden↔Town reachable on foot; current_area persists for town; 66 tests; round trip verified headless
- 2026-07-01 — P2-3 → done (att 1) PR#15 — worker big-pickle; growth decor moved to Garden (scripts/Garden.gd); House has no apply_world_stage; stage re-applied on boot+transition so growth persists across areas; 59 tests; ADULT cross-area verified headless
- 2026-07-01 — P2-2 → done (att 1) PR#14 — worker big-pickle; Door Area2D (walk-into-zone) + fade transition + Garden area; bidirectional House↔Garden; current_area saved on transition; 57 tests; boot+transition verified headless
- 2026-07-01 — P2-1 → done (att 1) PR#13 — worker big-pickle; AreaManager + dynamic area loading, House→scenes/areas/House.tscn, current_area saved; lead fixed AreaContainer parent + removed orphan World.tscn; 43 tests; merged+shipped
- 2026-07-01 — Phase 2 aligned (explore: House+Garden+Town, walk-into-door transitions, per-area growth decor, Town NPC greeting). 6 tasks P2-1..P2-6 written as todo.
- 2026-06-28 23:34:09 — P1-8 → done — worker big-pickle; Title+Settings+credits+stage label; Phase 1 COMPLETE; 3 tests
- 2026-06-28 23:28:02 — P1-7 → done — worker big-pickle; THE NOVELTY: growth adds persistent world decorations (tree@Kid, flowers@Adult); 4 tests
- 2026-06-28 23:20:22 — P1-6 → done — worker big-pickle; Stage enum + care_score + grew_up signal + neglect; 6 tests
- 2026-06-28 23:14:32 — P1-5 → done — worker big-pickle; care UI (bars+Eat/Rest/Play), decay+save wired; lead fixed Variant-inference in UI.gd + SaveManager.gd
- 2026-06-28 23:02:49 — P1-4 → done — worker big-pickle; SaveManager+TimeManager, offline-decay timestamp; 5 tests
- 2026-06-28 22:58:09 — P1-3 → done — worker big-pickle; Dweller pure-logic needs+decay; 6 tests
- 2026-06-28 22:54:49 — P1-2 → done — worker big-pickle; walkable room+camera; lead added visible placeholder sprite; player wired into Main
- 2026-06-28 22:46:59 — P1-1 → done (att 1) PR#3 — worker big-pickle; lead fixed sprite_frames + added scene test; merged+shipped

- 2026-06-28 — tracker created; harness being stood up by lead (Claude).

## Live URL

_(filled after P0-4 + first deploy)_ → https://pratyu2364-prime.github.io/pixel-dweller/
