# 🌑 Pixel Dweller: PENUMBRA — Live Tracker

**Single source of truth for execution.** Creative source of truth is
`docs/design/PENUMBRA.md`.

> Resume in a new session: *"Read TRACKER.md and continue the PENUMBRA revamp loop."*

## Control panel

```yaml
paused: false
reviewer: claude
retry_cap: 2
date: 2026-09-08
revamp: PENUMBRA          # total rewrite; legacy life-sim/combat build retired
```

## Legend

`todo` → `in_progress` → `in_review` (PR open, CI green) → `done` (merged + shipped)

## Task board

| ID | Title | Status | PR | Notes |
|----|-------|--------|----|-------|
| R0 | Revamp charter + tracker reset | done | #41 | closed stale P6 PRs #39/#40 |
| R1 | `LightField` — deterministic tile light sim | done | #42 | 18 tests; occlusion, ink, nooks |
| R2 | Umbra: coherence + ink + scatter/reform | done | #43 | ShadowState pure logic |
| R3 | Chamber format + loader (ASCII → room) | done | #44 | The Cistern playable |
| R4 | Cling + HUD | done | #45 | carry candles, smother braziers |
| R5 | Renderer: shader-driven look, Umbra as a hole | done | #46 | field → texture → palette |
| R6 | Wardens + chamber progression | done | #47 | Warden's Walk; Game sequence |
| R7 | The Orrery: orbiting lamps + sweeping beam | in_review | #48 | beams in LightField; floor −1 |
| R8 | Candle Rows (floor −2) + tutorialisation | todo | — | teaches Cling before the Walk |
| R9 | Candle Rows (floor −2) + whispers | in_review | — | teaches Cling; diegetic tutorial |
| R10 | The Prism Hall: mirrors + refraction | todo | — | hardest puzzle floor |
| R11 | Progression, save, chamber select, memories | todo | — | permanent ink/coherence upgrades |
| R12 | The Lantern Keeper + dual ending | todo | — | boss + finale |
| R13 | Title, audio, touch polish, ship | todo | — | deploy to Pages |
| R8 | Legacy purge: delete the retired build | in_review | #49 | 22 scripts, 9 scenes, 23 tests gone |

## Log

- **2026-09-08 · R9** — Candle Rows (floor −2) and whispers: teaching happens
  in the room, in her own voice, once, and fades on its own. No tooltips, no
  tutorial menu, no button that says "got it".
- **2026-09-08 · R8** — The old game is gone: Dweller, Stats, needs decay, life
  stages, NPCs, districts, shops, sword combat, slimes, the city map and every
  test that guarded them. What is left is PENUMBRA and nothing else.
- **2026-09-08 · R7** — Light that will not hold still. Beam cones in the
  LightField, orbiting lamps and a sweeping eye declared in front matter, and
  The Orrery (floor −1) built around them. Everything is a function of time, so
  a rhythm can be learned; nothing here is random.
- **2026-09-08 · R6** — Wardens exist. They never see Umbra; they notice
  *absence* — ink where light should be, or a light gone out — and walk over to
  put it back. The threat is not damage, it is that your darkness is borrowed.
  Chamber progression added: floors chain through `next:` or the climb order.
- **2026-09-08 · R0** — Total revamp begins. Owner: *"the existing game had
  obsolete structure and objective which didn't intrigue me at all… complete
  autonomy and creative freedom."* New concept: **PENUMBRA** — you are a shadow
  that can only exist where there is no light. Charter written, board rebuilt,
  stale P6 PRs (#39 loot/XP, #40 shop upgrades) closed as obsolete.
