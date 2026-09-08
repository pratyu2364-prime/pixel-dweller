# Pixel Dweller: PENUMBRA — game charter

> Total revamp (2026-09-08). The cozy life-sim + generic combat build is retired.
> This document is the creative source of truth. `TRACKER.md` is the execution
> source of truth.

## One line

**You are a shadow that came loose from its owner, and you can only exist where
there is no light.**

## Why this, and not another top-down adventure

Every mechanic hangs off a single physical rule — *light kills you* — instead of
off a stat sheet. Light is the terrain, the enemy, the puzzle, the timer and the
score. Nothing in the game needs an explanation beyond that one sentence, and a
player can be taught it in four seconds by walking into a sunbeam.

## The rule

The world is a grid. Every cell has a **light level** in `0.0 .. 1.0`.

- `light <= SHADE_MAX` → **shade**. Umbra is safe and moves at full speed.
- `light > SHADE_MAX` → **glare**. Umbra's **coherence** drains; at `0` she
  scatters and reforms at the last shade she stood in.

Coherence regenerates in deep shade. That single meter is health, stamina and
timer at once — there is no HP, no XP, no gold.

## The verbs (three, all usable with one thumb)

| Verb | Input | What it does |
|------|-------|--------------|
| **Move** | stick / WASD / drag | Free 8-way movement. Faster in deep shade, sluggish in glare. |
| **Cast** | tap / `Space` | Spend **ink** to throw a puff of darkness that lands on the grid and locally subtracts light for a few seconds. Bridges across lit floor. |
| **Cling** | hold / `E` near a light | Latch onto a light source and *drag it, dim it, or snuff it*. Snuffed lights stay out until a Warden relights them. |

Ink refills only in shade, so the loop is: *hide → charge → sprint the light →
hide*. Breathing in, breathing out.

## The antagonists

- **Wardens** — lantern-carrying keepers who walk fixed routes with a sweeping
  cone of light. They cannot see Umbra; they see *the absence of light*. Stand in
  a puff they walk over and they'll relight the room in alarm.
- **The Glare** — rooms with rising ambient light on a timer. Pure chase pressure.
- **The Lantern Keeper** — the final presence at the top of the Observatory.

## The place

The **Sunken Observatory**: a vertical stack of chambers, cellar → lantern room.
Each floor teaches exactly one new light behaviour before combining them.

| Floor | Chamber | Teaches |
|-------|---------|---------|
| −3 | The Cistern | shade vs. glare, coherence |
| −2 | Candle Rows | Cling: dragging and snuffing |
| −1 | The Orrery | Cast: bridging moving light |
| 0 | Warden's Walk | patrols, cones, alarm |
| +1 | The Prism Hall | mirrors, refracted beams |
| +2 | The Lantern Room | The Lantern Keeper |

## The choice at the top

At the Lantern Room Umbra can **rejoin her owner** (the lamp stays lit; the world
keeps its light and she goes back to being a shadow) or **snuff the great lamp**
(she becomes whole and free; the Observatory goes dark forever). Two endings,
one button, no morality meter telling you which is right.

## Aesthetic

Two-tone pixel art: a warm light palette and a cold void palette, with the
*player rendered as a hole in the light* rather than as a sprite with an outline.
Everything glows, nothing is outlined. Chunky 16px tiles, heavy bloom, dust motes
in every beam.

## Non-negotiable engineering constraints

1. **Light is simulated on a deterministic tile grid** (`LightField`), not read
   back from the GPU. Rendering is a separate, purely cosmetic layer. This keeps
   every mechanic unit-testable headlessly and cheap enough for WebGL.
2. Web export stays **non-threaded** (GitHub Pages has no COOP/COEP).
3. `main` is always green and deployed; each task ships as its own PR.
4. Touch-first: every verb reachable with one thumb; keyboard is the alias.

## What is being deleted

`Dweller`, `Stats`, needs/decay, life stages, NPC greetings, districts, shops,
sword combat, slimes, the city map, and the areas built on them. Reusable ideas
that survive in new form: ASCII → world building (`MapBuilder`), area/room
loading, the save layer and the camera rig.
