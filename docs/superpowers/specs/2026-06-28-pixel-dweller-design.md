# Pixel Dweller — Design Spec

**Date:** 2026-06-28
**Status:** Vision approved; Phase 1 ready for planning
**Type:** 2D top-down generational life-sim (Web / HTML5, hosted on GitHub Pages)

## Context

A beginner developer is building this game for his sister to play, hosted on
GitHub Pages and playable in any mobile or desktop browser via a link. The vision
grew from a single-room Tamagotchi into a walkable, Pokemon-style (Game Boy/DS)
cozy life-sim with a novel hook. Two AI helper agents (hermes, opencode)
independently converged on the novelty: **the world grows as the dweller grows**,
extended to a generational lineage. To keep this achievable, the single vision is
delivered in shippable phases. The senior engineer (Claude) leads; boilerplate is
delegated to hermes/opencode to conserve premium tokens.

NOTE: Target is web (not an app store). No developer fees, no store review — just
a GitHub Pages URL to share.

## Vision

A cozy, walkable top-down town. You raise a pixel dweller from baby to adult in
real time; **caring for them visibly transforms the town**. At adulthood you
retire the dweller and a new baby begins a new era — across generations you build
a civilization the town remembers. No battling. No ads/IAP. Offline. No accounts.

### The novelty (why it's fresh)

- **Care shapes the world** (hermes): the dweller's growth permanently rewrites
  the town — paths bloom, interiors recolor, ambiance evolves — making the world a
  co-authored memory of how you cared.
- **Lineage across generations** (opencode): each life stage grows the town; at
  adulthood you retire and start a new generation in a new era; NPCs and town
  persist and evolve. You play a lineage, not a single life.

## Player experience (end to end)

1. **First launch:** title -> "Begin" -> baby dweller appears in your house ->
   short tutorial (move, care) -> play. No login/paywall.
2. **Roam:** top-down, walk with on-screen d-pad/joystick (touch). House interior
   + yard (Phase 1); town added Phase 2. Camera follows player. Tile collision.
3. **Care:** interact with the dweller -> 3 need bars (Hunger/Energy/Mood) refill
   via actions (Eat/Rest/Play). Needs decay in real wall-clock time.
4. **While away:** decay computed on next open from the saved timestamp (no
   notifications on web).
5. **Growth payoff:** accumulated good care advances life stage
   (Baby -> Kid -> Adult) with an animation, AND triggers a permanent world change
   (Phase 1: one element, e.g. a tree blooms / area recolors).
6. **Lineage (Phase 3):** at Adult you may retire -> new baby, new era; town
   carries forward and keeps evolving.
7. **Settings:** sound on/off, notifications on/off, credits (Kenney attribution).

Feel: calm, cozy, bite-sized; meaningful long-term progress.

## Stack

- **Engine:** Godot 4.3+ (GDScript).
- **Export:** HTML5 / WebAssembly, **non-threaded (single-threaded) web build** so
  it runs on GitHub Pages, which cannot set the COOP/COEP headers a threaded build
  would require. This is a hard config requirement.
- **Hosting:** GitHub Pages (free). Shared as a URL; playable in mobile + desktop
  browsers. No install.
- **Art:** Kenney.nl CC0 packs (top-down character + tiles, UI).
- **Controls:** dual input — on-screen touch d-pad/joystick (mobile) AND
  WASD/arrow keys (desktop), same build.
- **Persistence:** browser storage — Godot maps `user://save.json` to IndexedDB
  per device/browser. No server/accounts.
- **Notifications:** none in the web build (mobile browsers cannot fire them
  reliably). Real-time decay is preserved via saved-timestamp computation on load.

## Phased delivery (each phase = a GitHub Pages release)

### Phase 1 — Foundation (FIRST SHIP) — scope of the upcoming impl plan

Walkable house interior + yard; dual touch/keyboard movement, collision,
camera-follow; the dweller lives in the house; 3 needs with real-time decay; care
actions; Baby -> Kid -> Adult growth; ONE permanent world change at a growth
milestone; save/load (browser storage); title + settings. Exported to HTML5 and
deployed to GitHub Pages.

Builds every foundation later phases need: tilemap, movement, save, needs, growth.

### Phase 2 — Living town

Roamable town (several buildings, 2-3 NPCs) beyond the house; each life stage
evolves one town element. Adds: town map, NPC system, stage->world hooks.

### Phase 3 — Lineage

Retire-at-adult -> new generation in a new era; town persists and remembers across
generations; NPCs age. Adds: generation/save-history system, era theming.

## Mechanics (Phase 1)

### Need bars (0-100, real-time decay)

| Need     | Refilled by | Decay rate |
|----------|-------------|------------|
| Hunger   | Eat         | medium     |
| Energy   | Rest        | slow       |
| Mood     | Play        | fast       |

On app open/resume, compute elapsed seconds since `last_saved_at`, apply
`decay_rate * elapsed`, clamp [0,100]. (No notifications in the web build; decay is
fully driven by the saved timestamp.)

### Life stages

Baby -> Kid -> Adult, advanced by accumulated **care score** (avg need-health
integrated over real days). Bars hitting 0 reduce care score (slower growth).
No death in v1. Each stage has its own sprite set. A growth event triggers a
permanent world change.

## Architecture (Godot scenes / scripts, Phase 1)

- `Main.tscn` — root; loads save, owns world + UI, runs updates.
- `World.tscn` — TileMap (house + yard), collision, spawn points, world-change
  hooks (e.g. swappable tiles/objects toggled by growth).
- `Player.gd` — dual input (touch d-pad + keyboard), 4-direction movement +
  animation, collision.
- `Dweller.gd` — needs state, decay math, care score, stage logic. Pure logic,
  UI-independent (unit-testable).
- `TimeManager.gd` — elapsed-time calc on open/resume from saved timestamp.
- `SaveManager.gd` — load/save JSON to `user://save.json` (IndexedDB on web).
- `UI.tscn` / `UI.gd` — need bars, action buttons, stage badge, touch d-pad.
- `Settings.tscn` — sound/notifications toggles, credits.

Each unit has one clear purpose and a defined interface; decay, care-score, save,
and growth thresholds are pure logic testable without UI.

## Cut from Phase 1 (later phases)

Town beyond the house/yard; NPCs; multi-element town evolution; lineage /
generations / eras; day-night; advanced audio; ads/IAP; dialogue; mini-games;
Google Maps world-generation.

## Verification (Phase 1)

- **Unit tests:** decay math, care-score accumulation, stage thresholds (Godot
  GUT or assert scenes). Pure logic, no UI.
- **Time simulation:** inject elapsed time in debug to fast-forward decay/growth.
- **Movement/collision:** manual walk test; cannot pass walls; camera follows.
- **World change:** force a growth event -> confirm the permanent world change
  applies and persists across save/reload.
- **Manual decay:** need high -> close tab -> reopen after N min -> bar dropped as
  expected (timestamp-driven).
- **Cross-platform:** desktop browser (keyboard) and mobile browser (touch) both
  play the full loop.
- **Deploy:** HTML5 export served on GitHub Pages loads and runs (verify the
  non-threaded build works without COOP/COEP headers).

## Build / delegation plan

- **Lead (Claude):** architecture, decay/care-score/stage/world-change logic, code
  review, integration, HTML5 export + GitHub Pages deploy guidance.
- **Workers (opencode / hermes):** Godot scene boilerplate, movement/UI wiring,
  CC0 asset hookup, repetitive scripts — handed tight specs, output reviewed.
- **User:** install Godot 4.3+, run in browser, taste feedback, create the GitHub
  repo + enable Pages for hosting (free).
