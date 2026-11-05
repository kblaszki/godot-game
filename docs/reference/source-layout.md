---
title: Source layout
diataxis: reference
audience: [ai, human]
related_code: [project.godot, engine/, lab/, games/, tests/, docs/, AGENTS.md, addons/gut/, .gutconfig.json]
related_docs:
  - ../index.md
  - ../explanation/architecture.md
  - engine-core.md
  - engine-input.md
  - engine-save.md
  - engine-audio.md
  - engine-scene-stack.md
  - lab-shell.md
keywords: [layout, inventory, paths, tests]
last_reviewed: 2026-11-04
---

# Source layout


Inventory of the lab tree. Update this page when paths are added, removed, or renamed.

## Root

| Path | Role |
|------|------|
| `project.godot` | Godot 4.x lab; GUT enabled; InputMap `pong_*` / `snake_*`; `run/main_scene` is `lab/lab_host.tscn` |
| `AGENTS.md` | Tool-neutral agent summary |
| `engine/` | Shared headless GDScript libraries |
| `lab/` | LayeredHost, lab host, launcher, WindowApplier |
| `games/` | Per-game `sim/`, `app/`, `docs/` |
| `tests/engine/` | GUT suites for `engine/` |
| `tests/lab/` | GUT suites for lab shell |
| `tests/games/` | Per-game GUT suites |
| `docs/` | Cross-game Diátaxis docs |
| `addons/gut/` | GUT **9.3.1** (vendored, plugin enabled) |
| `.gutconfig.json` | GUT dirs/prefix/suffix/`should_exit` for CLI and CI |
| `.github/workflows/ci.yml` | Ubuntu smoke + GUT (Godot 4.3) |
| `.cursor/rules/` | Cursor rules |
| `.cursor/skills/` | Cursor skills |

## Lab

| Path | Notes |
|------|-------|
| `lab/layered_host.gd` | Shared layered `SceneStack` host |
| `lab/lab_host.gd` | Main scene host; loads settings + `return_to_launcher` |
| `lab/launcher.gd` | Game registry UI |
| `lab/settings.gd` / `settings.tscn` | Lab display settings UI |
| `lab/window_applier.gd` | Applies `LabSettings` to a `Window` |
| `lab/godot_audio.gd` | Node audio adapter (`GodotAudio`) |

## Games

| Game | sim | app | docs | tests |
|------|-----|-----|------|-------|
| pong | `pong_config.gd`, `pong_sim.gd` | host extends LayeredHost + menu/play/pause | `games/pong/docs/` | `pong_sim_test.gd`, `pong_host_flow_test.gd` |
| snake | `snake_config.gd`, `snake_sim.gd` | host extends LayeredHost + menu/play/pause | `games/snake/docs/` | `snake_sim_test.gd`, `snake_host_flow_test.gd` |
| breakout | `breakout_config.gd`, `breakout_sim.gd` | host + menu/play/pause + `assets/` | `games/breakout/docs/` | `breakout_sim_test.gd`, `breakout_host_flow_test.gd` |
| districts | board/player/config/sim/bot | host + setup/play/pause + `assets/` (Kenney + iso tiles) | `games/districts/docs/` | `district_sim_test.gd`, `district_host_flow_test.gd` |

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
| `tests/lab/window_applier_test.gd` | windowed / fullscreen apply |
| `tests/games/pong/pong_sim_test.gd` | sim determinism / AI / scoring |
| `tests/games/pong/pong_host_flow_test.gd` | pause keep-alive |
| `tests/games/snake/snake_sim_test.gd` | snake rules / determinism |
| `tests/games/snake/snake_host_flow_test.gd` | snake pause keep-alive |
| `tests/games/breakout/breakout_sim_test.gd` | bricks / lives / determinism |
| `tests/games/breakout/breakout_host_flow_test.gd` | breakout pause keep-alive |
| `tests/games/districts/district_sim_test.gd` | board turns / bots / jail |
| `tests/games/districts/district_host_flow_test.gd` | setup / play / pause |
