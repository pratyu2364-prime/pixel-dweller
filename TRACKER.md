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
| R0 | Revamp charter + tracker reset | in_progress | — | this commit; closes stale P6 PRs |
| R1 | `LightField` — deterministic tile light sim | todo | — | shade/glare/propagation, headless-testable |
| R2 | Umbra: shadow movement + coherence + scatter/reform | todo | — | replaces Player/Stats |
| R3 | Chamber format + loader (ASCII → room) | todo | — | reuses MapBuilder ideas; The Cistern playable |
| R4 | Cast: ink puffs that subtract light | todo | — | ink meter, decay, bridging |
| R5 | Cling: drag / dim / snuff light sources | todo | — | Candle Rows |
| R6 | Renderer: two-tone light pass, player-as-hole, bloom, motes | todo | — | cosmetic layer only |
| R7 | Wardens: patrol routes, sweeping cones, alarm + relight | todo | — | Warden's Walk |
| R8 | The Orrery: moving lights + rotating beams | todo | — | combines R4 + R6 |
| R9 | The Prism Hall: mirrors + refraction | todo | — | hardest puzzle floor |
| R10 | Progression, save, chamber select, memories | todo | — | permanent ink/coherence upgrades |
| R11 | The Lantern Keeper + dual ending | todo | — | boss + finale |
| R12 | Title, tutorialisation, audio, touch polish, ship | todo | — | deploy to Pages |
| R13 | Legacy purge: delete retired life-sim/combat code | todo | — | after R2/R3 cover the ground |

## Log

- **2026-09-08 · R0** — Total revamp begins. Owner: *"the existing game had
  obsolete structure and objective which didn't intrigue me at all… complete
  autonomy and creative freedom."* New concept: **PENUMBRA** — you are a shadow
  that can only exist where there is no light. Charter written, board rebuilt,
  stale P6 PRs (#39 loot/XP, #40 shop upgrades) closed as obsolete.
