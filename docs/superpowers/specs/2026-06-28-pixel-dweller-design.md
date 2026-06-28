# Pixel Dweller — Design Spec (v1)

**Date:** 2026-06-28
**Status:** Approved for planning
**Type:** 2D life-simulation mobile game (Android / Google Play)

## Context

A beginner developer wants a fun, *production-grade*, Play-Store-shippable 2D
life-sim game, buildable over a few weekends. To keep scope realistic, v1 is a
tight, cozy Tamagotchi-style care loop — not a Sims clone. Two AI helper agents
(hermes, opencode) independently converged on the same shape: Godot 4, a single
dweller, quick-tap care sessions, real-time decay. This spec captures the agreed
v1. Implementation will be led by the senior engineer (Claude), delegating
boilerplate to hermes/opencode to conserve premium tokens.

## Concept

Raise one pixel dweller from baby to adult by keeping its needs healthy in real
time. Cozy, bite-sized, offline-friendly, portrait mobile. No ads, no IAP, no
internet, no accounts.

## Player experience (end to end)

1. **First launch:** title screen -> "Adopt" -> baby sprite appears in a room ->
   3-tap tutorial -> straight into play. No login/paywall.
2. **Main screen (portrait):** dweller idle-animating in room (top); 3 need bars
   (middle); 3 action buttons Eat/Rest/Play (bottom); stage badge (corner).
3. **Session (~60s):** tap actions -> need bars refill with animation + sound ->
   dweller looks content -> close app.
4. **While away:** needs decay in wall-clock time (computed on next open). A local
   notification fires when a need is predicted low: "I'm getting hungry!".
5. **Return:** app computes elapsed time, applies decay, shows mood-appropriate
   sprite + gentle welcome. No death/punishment in v1 — forgiving.
6. **Payoff:** accumulated good care triggers a growth animation:
   Baby -> Kid -> Adult. The v1 "win" is raising them well.
7. **Settings:** sound on/off, notifications on/off, credits (Kenney attribution).

Feel: calm, not stressful; bite-sized, not grindy. A 2026 Tamagotchi — open a few
times a day for 30 seconds, watch a life grow over a week.

## Stack

- **Engine:** Godot 4 (GDScript) — free, no royalties, one-click Android APK.
- **Art:** Kenney.nl CC0 packs (character, room/furniture, UI). Legal to sell, no
  attribution required (credited as courtesy).
- **Platform:** Android, portrait, offline. Free app.
  - NOTE: Google Play Console requires a one-time **$25 developer account fee**.
- **Persistence:** local JSON at `user://save.json`. No server, no accounts.

## Core loop

Open -> see dweller + needs -> tap actions to refill needs (earns care score) ->
good care over real days advances life stage, neglect slows it -> notification
pulls player back when a need is low -> repeat.

## Mechanics

### Need bars (0-100, real-time decay)

| Need     | Refilled by | Decay rate |
|----------|-------------|------------|
| Hunger   | Eat         | medium     |
| Energy   | Rest        | slow       |
| Mood     | Play        | fast       |

### Real-time decay

On app open (and on resume from background), compute elapsed seconds since
`last_saved_at`, apply `decay_rate * elapsed` to each need, clamp to [0, 100].
Schedule a local notification for the time a need is predicted to cross a "low"
threshold.

### Life stages

Baby -> Kid -> Adult. Advance on accumulated **care score**
(roughly: average need-health integrated over real days). Bars hitting 0 reduce
care score -> slower growth. No death in v1. Each stage = its own sprite set.

## Architecture (Godot scenes / scripts)

- `Main.tscn` — root; loads save, wires UI to Dweller, runs frame updates.
- `Dweller.gd` — needs state, decay math, care score, stage logic. The "brain".
  Pure logic, UI-independent (unit-testable).
- `TimeManager.gd` — elapsed-time calc on open/resume; notification scheduling.
- `SaveManager.gd` — load/save JSON to `user://save.json`.
- `UI.tscn` / `UI.gd` — need bars, action buttons, stage badge, animations.
- `Settings.tscn` — sound/notifications toggles, credits.

Each unit has one clear purpose and a defined interface; decay + care-score + save
are pure logic testable without UI.

## v1 scope (ships)

1 dweller; 3 needs; 3 actions; real-time decay; 3 life stages; save/load;
1 predictive notification; 1 room background; title screen; settings (sound +
notifications toggles); growth animation; mood-based sprite swaps.

## Cut from v1 (phase 2+)

Google Maps world-generation; room decorating / furniture shop; coins economy;
multiple dwellers; day/night cycle; advanced sound design; ads / IAP; dialogue;
mini-games.

## Verification

- **Unit tests:** decay math, care-score accumulation, stage-transition
  thresholds (Godot GUT or assert scenes). Pure-logic, no UI needed.
- **Time simulation:** inject elapsed time in debug to fast-forward decay + growth.
- **Manual:** set need high -> close -> reopen after N minutes -> confirm bar
  dropped by expected amount; confirm notification fires; confirm stage advances.
- **Device:** export debug APK -> run on phone/emulator -> full loop works.

## Build / delegation plan

- **Lead (Claude):** architecture, decay/care-score/stage math, code review,
  integration, Play Store guidance.
- **Workers (opencode / hermes):** Godot scene boilerplate, UI wiring, CC0 asset
  hookup, repetitive scripts — handed tight specs, output reviewed by lead.
- **User:** install Godot, run on device, taste feedback, pay $25 at publish time.
