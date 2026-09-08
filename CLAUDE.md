# Pixel Dweller

**PENUMBRA** — a 2D pixel puzzle-adventure where you are a shadow that can only
exist where there is no light (Godot 4.3 → HTML5 → GitHub Pages). Built by an
autonomous agent loop; the human only watches.

## Start here every session
1. Read **`TRACKER.md`** — single source of truth (status, control panel, log).
2. Read **`docs/design/PENUMBRA.md`** — the creative charter (the game's one rule).
3. To continue building, invoke the **`pixel-dweller`** skill, or run
   `bash scripts/dev-loop.sh once`.

## Roles
- **Claude (you):** designer + engineer + sole reviewer, writing the code directly
  during the PENUMBRA revamp.
- **CI/CD:** GitHub Actions (`.github/workflows/`) test + ship to Pages.

## Hard rules
- Web export must be **non-threaded** (GitHub Pages has no COOP/COEP headers).
- Light is a **deterministic tile-grid sim** (`LightField`), never a GPU readback,
  so every mechanic is unit-testable headlessly. Rendering is cosmetic only.
- `main` is always green + deployed. Tasks go via `feat/<id>` PRs only.
