# Pixel Dweller

Cozy 2D top-down web life-sim (Godot 4.3 → HTML5 → GitHub Pages) built for the
owner's sister. Built by an **autonomous agent loop**; the human only watches.

## Start here every session
1. Read **`TRACKER.md`** — single source of truth (status, control panel, log).
2. Read `docs/superpowers/plans/2026-06-28-pixel-dweller-implementation-plan.md`.
3. To continue building, invoke the **`pixel-dweller`** skill, or run
   `bash scripts/dev-loop.sh once`.

## Roles
- **Claude (you):** senior engineer + sole PR reviewer. Architecture + review only.
- **Workers:** opencode `big-pickle`, hermes `grok` — write code (saves budget).
- **CI/CD:** GitHub Actions (`.github/workflows/`) test + ship to Pages.

## Hard rules
- Web export must be **non-threaded** (GitHub Pages has no COOP/COEP headers).
- Owner is on a **$20 plan** — minimize Claude tokens; push codegen to workers.
- `main` is always green + deployed. Tasks go via `feat/<id>` PRs only.
