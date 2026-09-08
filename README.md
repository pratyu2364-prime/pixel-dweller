# PENUMBRA

**You are a shadow that came loose from its owner, and you can only exist where
there is no light.**

A small pixel puzzle-adventure that runs in a browser. Built by an autonomous
agent loop; the human watches.

▶︎ **[Play it](https://pratyu2364-prime.github.io/pixel-dweller/)**

## The rule

Every cell of the world has a light level. At or below the shade threshold you
are safe. Above it you are in **glare**, and your *coherence* — which is your
health, your stamina and your timer, all at once — drains until you scatter and
reform in the nearest shade you could actually have reached.

Coherence comes back in shade. **Ink** comes back only in *deep* shade. That one
restriction is the whole loop: hide, charge, sprint the light, hide.

## How to play

Open the link, press **begin**, and read **how to play** if you want the rule
before the room teaches it to you. The briefing is three cards — the rule, the
verbs, the meters — and it is also on the pause menu (**escape**), because the
verb you forget is the one you need halfway up a floor.

Nothing in the game chases you and nothing can kill you but light. If you get
stuck in a lit corner, pause and **start this floor over**; every floor is
proved winnable without ever standing in light, so a room is never a trap.

## Three verbs

| | keyboard | touch |
|---|---|---|
| **Move** | WASD / arrows | left half of the screen is a floating thumbstick |
| **Cast** | Space | right thumb — throws a puff of darkness that briefly bridges a lit floor |
| **Cling** | hold E | right thumb — lift a candle, turn a mirror, or lean on a brazier until it gives |

## The climb

The Sunken Observatory, cellar to lantern room. Each floor teaches one thing
before combining it with the last.

| Floor | Chamber | Teaches |
|-------|---------|---------|
| −3 | The Cistern | shade, glare, coherence |
| −2 | Candle Rows | Cling: lifting and smothering |
| −1 | The Orrery | light that keeps time |
| 0 | Warden's Walk | keepers who notice absence |
| +1 | The Prism Hall | beams, mirrors, aiming light |
| +2 | The Lantern Room | the lamp you were cast from |

It ends in a choice with no right answer, and the game does not grade it.

## How it is built

- **Godot 4.3**, GL Compatibility, exported to HTML5 **non-threaded** (GitHub
  Pages sends no COOP/COEP headers).
- Light is a **deterministic tile-grid simulation** (`LightField`) in plain
  GDScript, never a GPU readback. Rendering hands that grid to a shader as one
  texel per cell, so what you see and what the rules do cannot disagree — and
  every mechanic is unit-testable headlessly.
- Chambers are **plain text** under `chambers/`: an ASCII map plus front matter
  for wardens, orbits, beams, mirrors and whispers. A room is a diff.
- **No art or audio files.** The player is a drawn hole in the light, the world
  is a palette in a shader, and every sound is generated at runtime.

## Working on it

```bash
godot --headless --path . --import
# the fast suite — seconds
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
# the proofs — searches every chamber in space and time; a minute or two
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/proofs -gexit
```

`TRACKER.md` is the execution log; `docs/design/PENUMBRA.md` is the charter.
