---
title: Source layout
diataxis: reference
audience: [ai, human]
related_code: [project.godot, engine/, lab/, games/, tests/, docs/, art/, assets/, tools/, AGENTS.md, NOTICE, .cursor/skills/, addons/gut/, .gutconfig.json]
related_docs:
  - ../index.md
  - ../explanation/architecture.md
  - agent-skills.md
  - engine-core.md
  - engine-input.md
  - engine-save.md
  - engine-audio.md
  - engine-pxl-sheet.md
  - engine-scene-stack.md
  - lab-shell.md
  - ../how-to/make-pixel-art.md
keywords: [layout, inventory, paths, tests]
last_reviewed: 2026-11-09
---

# Source layout


Inventory of the lab tree. Update this page when paths are added, removed, or renamed.

## Root

| Path | Role |
|------|------|
| `project.godot` | Godot 4.x lab; GUT enabled; InputMap `pong_*` / `snake_*`; `run/main_scene` is `lab/lab_host.tscn` |
| `AGENTS.md` | Tool-neutral agent summary |
| `NOTICE` | Attribution for adapted Agent Skills and vendored pxl |
| `engine/` | Shared headless GDScript libraries |
| `lab/` | LayeredHost, lab host, launcher, Pixel Gallery, WindowApplier |
| `games/` | Per-game `sim/`, `app/`, `docs/` |
| `art/` | pxl sources (`art/pixel_demo/`, `art/gridward/`); `out/` gitignored; `.gdignore` |
| `assets/` | Shared committed art (e.g. `assets/pixel_demo/`) |
| `tools/` | Vendored CLIs (pxl); `.gdignore` |
| `tests/engine/` | GUT suites for `engine/` |
| `tests/lab/` | GUT suites for lab shell |
| `tests/games/` | Per-game GUT suites |
| `docs/` | Cross-game Diátaxis docs |
| `addons/gut/` | GUT **9.3.1** (vendored, plugin enabled) |
| `.gutconfig.json` | GUT dirs/prefix/suffix/`should_exit` for CLI and CI |
| `.github/workflows/ci.yml` | Ubuntu smoke + GUT (Godot 4.3) |
| `.cursor/rules/` | Cursor rules |
| `.cursor/skills/` | Cursor skills (scaffold + Headless First gamedev playbooks; map: [agent-skills.md](agent-skills.md)) |

## Lab

| Path | Notes |
|------|-------|
| `lab/layered_host.gd` | Shared layered `SceneStack` host |
| `lab/lab_host.gd` | Main scene host; loads settings + `return_to_launcher` |
| `lab/launcher.gd` | Game registry UI + Pixel Gallery / Settings |
| `lab/settings.gd` / `settings.tscn` | Lab display settings UI |
| `lab/pixel_gallery.gd` / `pixel_gallery.tscn` | pxl demo sprite browser |
| `lab/window_applier.gd` | Applies `LabSettings` to a `Window` |
| `lab/godot_audio.gd` | Node audio adapter (`GodotAudio`) |

## Games

| Game | sim | app | docs | tests |
|------|-----|-----|------|-------|
| pong | `pong_config.gd`, `pong_sim.gd` | host extends LayeredHost + menu/play/pause | `games/pong/docs/` | `pong_sim_test.gd`, `pong_host_flow_test.gd` |
| snake | `snake_config.gd`, `snake_sim.gd` | host extends LayeredHost + menu/play/pause | `games/snake/docs/` | `snake_sim_test.gd`, `snake_host_flow_test.gd` |
| breakout | `breakout_config.gd`, `breakout_sim.gd` | host + menu/play/pause + `assets/` | `games/breakout/docs/` | `breakout_sim_test.gd`, `breakout_host_flow_test.gd` |
| districts | board/player/config/sim/bot/chance/gadgets/network stubs | host + setup/play/pause + baker + `board_3d` + `district_audio` + `assets/` | `games/districts/docs/` | `district_sim_test.gd`, `district_host_flow_test.gd`, `district_tile_baker_test.gd` |
| minigolf | config/hole/course/ball/score/sim/bot | host + menu/setup/play/pause/results + `course_3d` + audio | `games/minigolf/docs/` | physics/sim/bot/host_flow |
| gridward | `gridward_config.gd`, `map_def.gd`, `enemy_def.gd`, `tower_def.gd`, `wave_def.gd`, `gridward_catalog.gd`, `gridward_progress.gd`, `enemy_state.gd`, `status_effect.gd`, `tower_state.gd`, `projectile_state.gd`, `gridward_sim.gd`, `gridward_bot.gd`, `gridward_events.gd` | host extends LayeredHost + menu/map_select/play/pause_menu/results + `progress_store` + `board_3d` + `gridward_audio` + `assets/pxl/` | `games/gridward/docs/` (spec + `plans/` 00–12 + reference/explanation, including `reference/balance.md` and `reference/app.md`) | `gridward_catalog_test.gd`, `gridward_sim_test.gd`, `gridward_towers_test.gd`, `gridward_economy_test.gd`, `gridward_lane_holds_test.gd`, `gridward_roster_test.gd`, `gridward_bot_test.gd`, `gridward_progress_test.gd`, `gridward_campaign_test.gd`, `gridward_host_flow_test.gd`, `gridward_play_test.gd`, `gridward_board3d_test.gd`, `gridward_juice_test.gd` |

## Engine modules

| Path | Notes |
|------|-------|
| `engine/fixed_tick.gd` | `FixedTick.SEC` fixed step |
| `engine/seeded_rng.gd` | `SeededRng` seeded RNG wrapper |
| `engine/view_fit.gd` | Uniform scale + offset to fit content in viewport |
| `engine/input_state.gd` | `InputState` held/edge actions |
| `engine/high_score_table.gd` | Fixed-capacity descending scores |
| `engine/score_store.gd` | Load/save high-score text files |
| `engine/lab_settings.gd` | Display mode + resolution profile |
| `engine/settings_store.gd` | Load/save `LabSettings` text files |
| `engine/null_audio.gd` | Headless no-op audio port |
| `engine/pxl_sheet.gd` | `PxlSheet` atlas / anim JSON parser |
| `engine/scene_request.gd` | `SceneRequest` PUSH/POP/REPLACE/QUIT |
| `engine/scene_stack.gd` | `SceneStack` request queue + apply + `paths()` |

## Tests

| Suite | Covers |
|-------|--------|
| `tests/engine/fixed_tick_test.gd` | `FixedTick.SEC` |
| `tests/engine/seeded_rng_test.gd` | same-seed / different-seed |
| `tests/engine/view_fit_test.gd` | letterbox / pillarbox / degenerate |
| `tests/engine/input_state_test.gd` | `InputState` held/edges/axis |
| `tests/engine/high_score_table_test.gd` | insert / qualifies / ties |
| `tests/engine/score_store_test.gd` | load/save / corrupt / missing |
| `tests/engine/lab_settings_test.gd` | defaults / normalize / duplicate |
| `tests/engine/settings_store_test.gd` | load/save / corrupt / unknown resolution |
| `tests/engine/null_audio_test.gd` | `NullAudio` + `AudioSpy` |
| `tests/engine/scene_stack_test.gd` | `SceneStack` apply + `paths()` |
| `tests/mocks/audio_spy.gd` | Records `play` calls for GUT |
| `tests/lab/lab_host_flow_test.gd` | launcher ↔ pong host nesting |
| `tests/lab/lab_settings_flow_test.gd` | launcher ↔ settings; persist resolution |
| `tests/lab/pixel_gallery_flow_test.gd` | Pixel Gallery sheet load, variant, back |
| `tests/lab/window_applier_test.gd` | windowed / fullscreen apply |
| `tests/engine/pxl_sheet_test.gd` | `PxlSheet` rects, tags, invalid JSON |
| `tests/games/pong/pong_sim_test.gd` | sim determinism / AI / scoring |
| `tests/games/pong/pong_host_flow_test.gd` | pause keep-alive |
| `tests/games/snake/snake_sim_test.gd` | snake rules / determinism |
| `tests/games/snake/snake_host_flow_test.gd` | snake pause keep-alive |
| `tests/games/breakout/breakout_sim_test.gd` | bricks / lives / determinism |
| `tests/games/breakout/breakout_host_flow_test.gd` | breakout pause keep-alive |
| `tests/games/districts/district_sim_test.gd` | board turns / bots / jail |
| `tests/games/districts/district_host_flow_test.gd` | setup / play / pause |
| `tests/games/districts/district_tile_baker_test.gd` | procedural iso tile faces |
| `tests/games/minigolf/minigolf_physics_test.gd` | putt bounce / sink / OOB |
| `tests/games/minigolf/minigolf_sim_test.gd` | hotseat / course complete |
| `tests/games/minigolf/minigolf_bot_test.gd` | bot determinism |
| `tests/games/minigolf/minigolf_host_flow_test.gd` | menu / play / pause |
| `tests/games/gridward/gridward_catalog_test.gd` | Meadow path, buildable mask, wave ids, spec tables |
| `tests/games/gridward/gridward_sim_test.gd` | wave phase, path leftover, leak, victory, defeat, same-seed |
| `tests/games/gridward/gridward_towers_test.gd` | place, sell, upgrade, targeting, bolt hitscan, mortar splash |
| `tests/games/gridward/gridward_economy_test.gd` | kill bounty, wave-clear bonus, early call, upgrade curve |
| `tests/games/gridward/gridward_lane_holds_test.gd` | Meadow waves 3–6 hold on two bolts |
| `tests/games/gridward/gridward_roster_test.gd` | armor, air targeting, frost slow, beam ramp, swarm count, burn |
| `tests/games/gridward/gridward_bot_test.gd` | Meadow Normal clear, same-seed, seed sweep |
| `tests/games/gridward/gridward_progress_test.gd` | progress round-trip, v1 migration, corrupt file |
| `tests/games/gridward/gridward_campaign_test.gd` | star gates, unlock chain, map teach beats, difficulty HP and gold |
| `tests/games/gridward/gridward_host_flow_test.gd` | menu to map select to play to pause to results; quit returns to lab |
| `tests/games/gridward/gridward_play_test.gd` | place via sim, tower panel, start wave, 2× steps |
| `tests/games/gridward/gridward_board3d_test.gd` | cell center, world roundtrip, yaw, headless board sync, camera trauma |
| `tests/games/gridward/gridward_juice_test.gd` | cue map, hit-stop, leak trauma, icon sheet, nearest build icons |
