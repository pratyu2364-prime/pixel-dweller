# Pixel Dweller — Implementation Plan (Phase 0 + Phase 1)

Spec: `docs/superpowers/specs/2026-06-28-pixel-dweller-design.md`
Tracker (live status): `TRACKER.md`

This plan is executed by an **autonomous loop** (see `scripts/dev-loop.sh` +
`TRACKER.md`). Each task = one feature branch -> PR -> CI -> Claude review ->
auto-merge -> deploy. Workers (opencode big-pickle / hermes Grok) write code;
Claude reviews; free CI tests; GitHub Pages ships.

## Operating model

- **Source of truth:** `TRACKER.md` + `tasks/*.md`. Any session resumes by reading
  these. Tokens exhausted -> new session -> "resume from tracker".
- **One task at a time**, smallest shippable slice. `main` always green + deployed.
- **Budget guardrails:** cron tick is a shell script (free); Claude invoked only to
  review a green PR; retry cap 2 then escalate model then mark `blocked` + stop;
  `TRACKER.md` has `PAUSED` flag + daily task cap respected by cron.

## Phase 0 — Pipeline (must finish before Phase 1 feature work)

- **P0-1 Godot project skeleton** — `project.godot` (portrait, GL compat for web),
  folder layout (`scenes/ scripts/ assets/ tests/`), `.gitignore`,
  `.gitattributes`, placeholder `Main.tscn` that boots.
- **P0-2 GUT test framework** — add GUT addon under `addons/gut/`; a trivial
  passing test proves headless test runs.
- **P0-3 CI workflow** — `.github/workflows/ci.yml`: gdlint/gdformat, GUT headless,
  boot smoke, trial HTML5 export, PR preview artifact.
- **P0-4 Deploy workflow** — `.github/workflows/deploy.yml`: non-threaded HTML5
  export on push to `main` -> GitHub Pages.
- **P0-5 Driver + skill** — `scripts/dev-loop.sh` (the autonomous loop) + cron
  registration; verify a dry run picks the next task from `TRACKER.md`.

Exit: an empty-but-real game boots, one dummy test passes in CI, a push to main
deploys a "hello" page to Pages, driver dry-run works.

## Phase 1 — Foundation gameplay (first real ship)

- **P1-1 Player movement** — top-down `Player` scene, 4-dir move + idle/walk anim,
  dual input (touch d-pad + WASD/arrows). Tests: input vector -> velocity mapping.
- **P1-2 World + collision** — `World` TileMap (house interior + yard) from Kenney
  tiles, collision layer, camera-follow, spawn point. Test: scene loads, collision
  shapes present.
- **P1-3 Needs + real-time decay** — `Dweller.gd` pure logic: 3 needs, decay rates,
  `apply_elapsed(seconds)`, clamp. Tests: decay math, clamping, zero/long elapsed.
- **P1-4 Save/load** — `SaveManager.gd` JSON to `user://save.json` incl.
  `last_saved_at`; `TimeManager.gd` computes elapsed on load. Tests: round-trip,
  elapsed calc.
- **P1-5 Care actions + UI** — `UI` need bars + Eat/Rest/Play buttons wired to
  Dweller; refill + feedback. Test: action raises correct need.
- **P1-6 Life stages + growth** — care-score accumulation, Baby->Kid->Adult
  thresholds, stage sprite swap, growth event signal. Tests: thresholds, neglect
  penalty.
- **P1-7 World-change on growth** — one permanent world element toggled by the
  growth event (e.g. a tree blooms); persisted in save. Test: event -> state set ->
  survives reload.
- **P1-8 Polish + first ship** — title screen, settings (sound/notif toggles unused
  on web -> sound only), credits (Kenney). Manual L5 checklist on phone via preview.

Exit: walkable game where you care for a dweller that grows Baby->Adult and visibly
changes the world; live on GitHub Pages; your sister can play the URL.

## Per-task contract (what each `tasks/*.md` defines)

`id`, `title`, `phase`, `depends_on`, `status`, `worker` (model), `acceptance`
(testable criteria), `files` (expected paths), `notes`. The driver reads these.

## Verification

Per task: GUT tests green (L1/L2), boot smoke (L3), export ok (L4); visual tasks
get L5 preview check. Phase exit criteria above. Final: load the Pages URL on a
phone + desktop, play the full loop.
