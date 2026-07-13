# 🛰️ Pixel Dweller — Live Tracker

**This file is the single source of truth.** Humans read it to watch progress.
Agents read it to know what to do next and to resume after a session/token reset.

> To resume in a new session: *"Read TRACKER.md and continue the autonomous build."*

## Control panel (edit these to steer the loop)

```yaml
paused: false            # set true to halt the cron loop immediately
max_tasks_per_day: 8     # cron stops after this many merged tasks/day
default_worker: opencode/big-pickle   # primary codegen model
escalation_worker: hermes/grok        # used after 2 failed attempts
reviewer: claude         # only Claude reviews/merges
retry_cap: 2             # attempts before escalating model
date: 2026-07-14
tasks_merged_today: 1
```

## Legend
`todo` → `in_progress` → `in_review` (PR open, CI green, awaiting Claude) →
`done` (merged + shipped) · `blocked` (needs human) · `failed` (retrying)

## Task board

| ID | Phase | Title | Status | Worker | PR | Attempts | Notes |
|----|-------|-------|--------|--------|----|---------:|-------|
| P0-1 | 0 | Godot project skeleton | done | — | — | 0 | boots empty Main.tscn |
| P0-2 | 0 | GUT test framework | done | — | — | 0 | one passing test |
| P0-3 | 0 | CI workflow | done | — | — | 0 | tests+export+preview |
| P0-4 | 0 | Deploy workflow | done | — | — | 0 | Pages on main |
| P0-5 | 0 | Driver + cron dry-run | done | — | — | 0 | loop picks next task |
| P1-1 | 1 | Player movement (touch+keys) | done | — | — | 0 | depends P0 |
| P1-2 | 1 | World + collision + camera | done | — | — | 0 | depends P1-1 |
| P1-3 | 1 | Needs + real-time decay | done | — | — | 0 | pure logic |
| P1-4 | 1 | Save/load + elapsed time | done | — | — | 0 | IndexedDB on web |
| P1-5 | 1 | Care actions + UI | done | — | — | 0 | bars + buttons |
| P1-6 | 1 | Life stages + growth | done | — | — | 0 | Baby→Kid→Adult |
| P1-7 | 1 | World-change on growth | done | — | — | 0 | the novelty seed |
| P1-8 | 1 | Polish + first ship | done | — | — | 0 | title+settings+credits |
| P2-1 | 2 | Area framework + dynamic loading | done | big-pickle | #13 | 1 | House loaded via AreaManager; saves current_area |
| P2-2 | 2 | Door transitions + Garden | done | big-pickle | #14 | 1 | walk-into-door + fade; House↔Garden |
| P2-3 | 2 | Growth decor → Garden | done | big-pickle | #15 | 1 | per-area novelty; House clean |
| P2-4 | 2 | Town area + door | done | big-pickle | #16 | 1 | 3 areas reachable on foot |
| P2-5 | 2 | Town NPC greeting | done | big-pickle | #17 | 1 | dialog + cooldown mood boost |
| P2-6 | 2 | Phase 2 polish + ship | done | big-pickle | #18 | 1 | area label; full tour; ship |
| P3-1 | 3 | Zoomed-out camera + bounds clamp | done | claude | #19 | 1 | zoom 2.0; CameraRig clamp; House 2.5 |
| P3-2 | 3 | MapBuilder ASCII→world core | done | claude | #20 | 1 | runtime tileset; tile collision |
| P3-3 | 3 | Big city map v1 | done | claude | #21 | 1 | 100x120 cells; BFS-verified; replaces Town |
| P3-4 | 3 | Enterable buildings (interiors) | done | claude | #22 | 1 | Shop + NeighborHouse; AreaMap base |
| P3-5 | 3 | Populate city: NPCs + districts | done | claude | #23 | 1 | 6 NPCs; 8 districts; live label |
| P3-6 | 3 | Phase 3 polish + ship | done | claude | #24 | 1 | full tour + door-graph invariant; ship |
| P6-1 | 6 | Player stats + hearts HUD | done | claude | #35 | 1 | COMBAT PIVOT (owner: full freedom) |
| P6-2 | 6 | Sword attack | done | claude | #36 | 1 | swing hitbox + anim |
| P6-3 | 6 | Enemy framework + Slime | done | claude | #37 | 1 | wander/chase/hurt/die; player invuln+blink |
| P6-4 | 6 | Whispering Woods danger area | done | claude | #38 | 1 | woods + slimes; town safe; respawn home |
| P6-5 | 6 | Loot, XP, levels | in_review | claude | #39 | 1 | CI green; awaiting owner merge (permission gate) |
| P6-6 | 6 | Shop upgrades | in_review | claude | #40 | 1 | stacked on #39; awaiting owner merges |
| P6-7 | 6 | Boss + polish + ship | todo | claude | — | 0 | Giant Frog; balance; deploy |

## Activity log (newest first — agents append one line per action)
- 2026-07-14 — P6-6 → in_review PR#40 (stacked on #39) — lead; sword/armor tiers (Wooden→Iron→Hero / Clothes→Leather→Knight), pure next_tier/can_afford, buy swaps flat bonus (no stacking), shop buttons near shopkeeper NPCs w/ live offer+afford state, tiers persisted; 166 tests. Merge order: #39 then #40 (auto-retargets).
- 2026-07-14 — P6-5 → in_review PR#39 — lead; enemy defeat pays coins+xp (Main wires Enemy.defeated per area), level-up cheer dialog + autosave, LootLabel HUD (pure loot_text), persistence round-trip; 158 tests, CI green. Merge needs owner (per-PR permission gate).
- 2026-07-14 — P6-4 → done (merged by owner instruction) PR#38 — lead; Whispering Woods (48x34 forest, 11 slime spawns via new MapBuilder 'e' spawn cells), city north door in East Orchard, defeat = heal_full + fade home (kid-friendly), town-safety + BFS reachability tests; 153 tests, CI green. Merge blocked by session permission gate — needs owner to merge #38 or approve self-merge.
- 2026-07-11 — P6-3 → done PR#37 — lead; Enemy framework (wander/chase/hurt/die pure fns, contact dmg, knockback, poof death) + Slime; player hurt() w/ 0.8s invuln+blink wired to Stats hearts; 145 tests. Backfilled tracker: P6-1 done #35, P6-2 done #36.
- 2026-07-05 — Phase 6 aligned: COMBAT ADVENTURE (owner grants full freedom: health/armor/swords/levels/enemies/boss). Kid-friendly tone. 7 tasks P6-1..P6-7. Assets: Ninja Adventure monsters/weapons/hearts via ZeldaCourse mirror.
- 2026-07-05 — P5-4 → done PR#34 — lead; map extended 100→140 wide: East Orchard district (tree rows, lake w/ banks, 7 farm houses, 2 new NPCs: Ines, Momo); .gdlintrc 150-col for layout rows; 128 tests
- 2026-07-05 — P5-3 → done PR#33 — lead; furnished interiors (8 furniture props) + residents Sana (shop) & Yuki (neighbor house) with met-tracking
- 2026-07-05 — P5-2 → done PR#32 — lead; one-time NPC dialogue: intro+boost first meeting, repeat line after; met_npcs persisted per npc_id (seed of per-NPC memory); NPC types + names
- 2026-07-05 — P5-1 → done PR#31 — lead; care HUD hidden + decay paused (explorer pivot per owner); HUD = area label + dialog + Talk
- 2026-07-05 — P4-4 → done PR#29 — lead; water bank edges via pure water_variant() 4-neighbor mask (river/fountain/ponds get foam edges, bridges pass through); 123 tests; deployed
- 2026-07-05 — P4-3 → done PR#28 — lead; civic/museum/apartment slabs → house sprite clusters (~44 houses citywide); layout-only, BFS re-verified
- 2026-07-05 — P4-2 → done PR#27 — lead; NPC sprites (samurai blue/green, idle anim, faces player via pure facing_toward); 121 tests
- 2026-07-05 — P4-1 → done PR#26 — lead; REAL PIXEL ART: Ninja Adventure tilesets (grass/road/water/pavers/brick), tree+flower+house sprite props w/ y-sort + footprint collision, 20 houses in residential, red market shops, nearest-neighbor filtering; python-composited previews used to verify art before shipping; 118 tests
- 2026-07-05 — P4-0 → done PR#25 — lead; desktop viewport 1280x720 (was 540x960 portrait); House+Garden rebuilt as MapBuilder tile rooms (owner: "just green screen"); World.gd removed; 114 tests
- 2026-07-05 — P3-6 → done PR#24 — lead; full-tour test (9 stops), boot-from-every-save, door-graph invariant (7 doors), bad-entry fallback; 114 tests; PHASE 3 COMPLETE — the world is a city now
- 2026-07-05 — P3-5 → done PR#23 — lead; 6 NPCs across districts + 8 named districts w/ live label (pure district_for + 0.3s poll); 110 tests
- 2026-07-05 — P3-4 → done PR#22 — lead; Shop + NeighborHouse interiors (AreaMap base, zoom 2.5), city doors + return markers; fixed roads overdrawn by houses; 103 tests
- 2026-07-05 — P3-3 → done PR#21 — lead; 100x120-cell city (districts/river/bridges/plaza), BFS-verified connectivity, "town" key → City.tscn (legacy saves fine), Entry1→EntryFromGarden alias; 97 tests
- 2026-07-05 — P3-2 → done PR#20 — lead; MapBuilder core (ASCII→TileMapLayer, runtime tileset, tile collision); found+fixed: atlas must join TileSet before physics data; 89 tests
- 2026-07-05 — P3-1 → done PR#19 — lead; camera 3.5→2.0 + CameraRig bounds clamp + per-area zoom; 81 tests. NOTE: workers down (big-pickle API err x2, hermes blocked); owner authorized lead codegen + self-merge this session
- 2026-07-05 — Phase 3 aligned (WORLD BUILDING: zoom out camera 3.5→2.0 + clamp; data-driven ASCII MapBuilder [lead-written]; huge Pokemon-style city w/ districts/river/plaza replacing Town; interiors; NPCs). Game objective deliberately deferred by owner. 6 tasks P3-1..P3-6 todo.
- 2026-07-01 — P2-6 → done (att 1) PR#18 — worker big-pickle; area name label (updates on transition) + robust entry fallback (boot from saved town); PHASE 2 COMPLETE; 76 tests; full tour + town-boot verified headless
- 2026-07-01 — P2-5 → done (att 1) PR#17 — worker big-pickle; Town NPC greeting (dialog + cooldown mood boost); interact action (E/Space) + touch Talk button; greet() pure cooldown logic; 69 tests; +10 mood once then cooldown verified headless
- 2026-07-01 — P2-4 → done (att 1) PR#16 — worker big-pickle; Town area (distinct) + Garden↔Town doors; House↔Garden↔Town reachable on foot; current_area persists for town; 66 tests; round trip verified headless
- 2026-07-01 — P2-3 → done (att 1) PR#15 — worker big-pickle; growth decor moved to Garden (scripts/Garden.gd); House has no apply_world_stage; stage re-applied on boot+transition so growth persists across areas; 59 tests; ADULT cross-area verified headless
- 2026-07-01 — P2-2 → done (att 1) PR#14 — worker big-pickle; Door Area2D (walk-into-zone) + fade transition + Garden area; bidirectional House↔Garden; current_area saved on transition; 57 tests; boot+transition verified headless
- 2026-07-01 — P2-1 → done (att 1) PR#13 — worker big-pickle; AreaManager + dynamic area loading, House→scenes/areas/House.tscn, current_area saved; lead fixed AreaContainer parent + removed orphan World.tscn; 43 tests; merged+shipped
- 2026-07-01 — Phase 2 aligned (explore: House+Garden+Town, walk-into-door transitions, per-area growth decor, Town NPC greeting). 6 tasks P2-1..P2-6 written as todo.
- 2026-06-28 23:34:09 — P1-8 → done — worker big-pickle; Title+Settings+credits+stage label; Phase 1 COMPLETE; 3 tests
- 2026-06-28 23:28:02 — P1-7 → done — worker big-pickle; THE NOVELTY: growth adds persistent world decorations (tree@Kid, flowers@Adult); 4 tests
- 2026-06-28 23:20:22 — P1-6 → done — worker big-pickle; Stage enum + care_score + grew_up signal + neglect; 6 tests
- 2026-06-28 23:14:32 — P1-5 → done — worker big-pickle; care UI (bars+Eat/Rest/Play), decay+save wired; lead fixed Variant-inference in UI.gd + SaveManager.gd
- 2026-06-28 23:02:49 — P1-4 → done — worker big-pickle; SaveManager+TimeManager, offline-decay timestamp; 5 tests
- 2026-06-28 22:58:09 — P1-3 → done — worker big-pickle; Dweller pure-logic needs+decay; 6 tests
- 2026-06-28 22:54:49 — P1-2 → done — worker big-pickle; walkable room+camera; lead added visible placeholder sprite; player wired into Main
- 2026-06-28 22:46:59 — P1-1 → done (att 1) PR#3 — worker big-pickle; lead fixed sprite_frames + added scene test; merged+shipped

- 2026-06-28 — tracker created; harness being stood up by lead (Claude).

## Live URL

_(filled after P0-4 + first deploy)_ → https://pratyu2364-prime.github.io/pixel-dweller/
