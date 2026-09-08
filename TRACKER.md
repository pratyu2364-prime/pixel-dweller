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
| R4 | Cling + HUD | in_review | #45 | carry candles, smother braziers |
| R5 | Renderer: shader-driven look, Umbra as a hole | in_review | #46 | field → texture → palette |
| R6 | Wardens + chamber progression | in_review | — | Warden's Walk; Game sequence |
| R7 | The Orrery: moving lights, rotating beams | todo | — | combines cast + carry |
| R8 | Candle Rows (floor −2) + tutorialisation | todo | — | teaches Cling before the Walk |
| R9 | The Prism Hall: mirrors + refraction | todo | — | hardest puzzle floor |
| R10 | Progression, save, chamber select, memories | todo | — | permanent ink/coherence upgrades |
| R11 | The Lantern Keeper + dual ending | todo | — | boss + finale |
| R12 | Title, tutorialisation, audio, touch polish, ship | todo | — | deploy to Pages |
| R13 | Legacy purge: delete retired life-sim/combat code | todo | — | after R2/R3 cover the ground |

## Log

- **2026-09-08 · R6** — Wardens exist. They never see Umbra; they notice
  *absence* — ink where light should be, or a light gone out — and walk over to
  put it back. The threat is not damage, it is that your darkness is borrowed.
  Chamber progression added: floors chain through `next:` or the climb order.
- **2026-09-08 · R0** — Total revamp begins. Owner: *"the existing game had
  obsolete structure and objective which didn't intrigue me at all… complete
  autonomy and creative freedom."* New concept: **PENUMBRA** — you are a shadow
  that can only exist where there is no light. Charter written, board rebuilt,
  stale P6 PRs (#39 loot/XP, #40 shop upgrades) closed as obsolete.
