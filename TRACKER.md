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
| R9 | Candle Rows (floor −2) + whispers | in_review | #50 | teaches Cling; diegetic tutorial |
| R10 | The Prism Hall: mirrors + traced rays | in_review | #51 | turnable glass; floor +1 |
| R11 | Title + save/progress + touch controls | in_review | #52 | phone-playable; descend where you left off |
| R12 | The Lantern Room: Keeper + dual ending | in_review | #53 | the climb is completable end to end |
| R13 | Procedural audio + README + ship | in_review | #54 | zero audio files; six generated voices |
| R14 | ChamberProver: fairness proof per floor | in_review | #55 | searches space+time; runs in CI |
| R15 | Presentation: name, floor cards, pause, shake | in_review | #56 | project is now PENUMBRA |
| R16 | Memories: optional risk, permanent boons | in_review | — | one per floor, always in glare |
| R8 | Legacy purge: delete the retired build | in_review | #49 | 22 scripts, 9 scenes, 23 tests gone |

## Log

- **2026-09-08 · R16** — The only progression in the game: one memory per
  floor, each standing in light with shade one step away, each carrying a line
  about the woman she was cast from. They raise two ceilings and nothing else.
- **2026-09-08 · R15** — The project is called what the game is called. Floor
  cards name each chamber on arrival and leave on their own, a pause menu can
  always start a floor over (a puzzle game that can be soft-locked is a broken
  one), and the frame kicks exactly once — when she scatters.
- **2026-09-08 · R14** — Fairness is proved, not eyeballed. ChamberProver
  searches each floor in space *and time* and every chamber in the climb now
  ships with a proof that a route exists which never stands in glare.
- **2026-09-08 · R13** — Sound, without a single audio file: six voices
  generated at runtime from shaped oscillators and breath. README rewritten
  around the rule. The build ships to Pages on merge.
- **2026-09-08 · R12** — The climb has a top. The Great Lamp will not be
  touched while its three feeders burn; the Keeper walks toward her the whole
  time, slower than she is, carrying the last flame. Two endings, no score, and
  the game never says which one was right.
- **2026-09-08 · R11** — A way in and a way back: title screen, a save that
  remembers the deepest floor and what it cost, and floating-thumbstick touch
  controls so this is playable on a phone.
- **2026-09-08 · R10** — Rays and mirrors. Beams are traced cell by cell,
  reflect off turnable glass and stop at walls, and Cling turns a mirror you
  stand beside — the first thing in the Observatory that answers to the player.
  The Prism Hall (floor +1) closes the climb for now.
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
