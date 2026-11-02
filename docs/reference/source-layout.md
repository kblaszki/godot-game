---
title: Source layout
diataxis: reference
audience: [ai, human]
related_code: [project.godot, engine/, lab/, games/, tests/, docs/, AGENTS.md, addons/gut/]
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
last_reviewed: 2026-11-02
---

# Source layout

Inventory of the lab tree. Update this page when paths are added, removed, or renamed.

## Root

| Path | Role |
|------|------|
| `project.godot` | Godot 4.x lab; GUT enabled; InputMap `pong_*` / `snake_*`; `run/main_scene` is `lab/lab_host.tscn` |
| `AGENTS.md` | Tool-neutral agent summary |
| `engine/` | Shared headless GDScript libraries |
| `lab/` | LayeredHost, lab host, launcher |
| `games/` | Per-game `sim/`, `app/`, `docs/` |
| `tests/engine/` | GUT suites for `engine/` |
| `tests/lab/` | GUT suites for lab shell |
| `tests/games/` | Per-game GUT suites |
| `docs/` | Cross-game Diátaxis docs |
| `addons/gut/` | GUT **9.3.1** (vendored, plugin enabled) |
| `.github/workflows/ci.yml` | Ubuntu smoke + GUT (Godot 4.3) |
| `.cursor/rules/` | Cursor rules |
| `.cursor/skills/` | Cursor skills |

## Lab

| Path | Notes |
|------|-------|
| `lab/layered_host.gd` | Shared layered `SceneStack` host |
| `lab/lab_host.gd` | Main scene host; `return_to_launcher` |
| `lab/launcher.gd` | Game registry UI |
| `lab/godot_audio.gd` | Node audio adapter (`GodotAudio`) |

## Games

| Game | sim | app | docs | tests |
|------|-----|-----|------|-------|
| pong | `pong_config.gd`, `pong_sim.gd` | host extends LayeredHost + menu/play/pause | `games/pong/docs/` | `pong_sim_test.gd`, `pong_host_flow_test.gd` |
| snake | `snake_config.gd`, `snake_sim.gd` | host extends LayeredHost + menu/play/pause | `games/snake/docs/` | `snake_sim_test.gd`, `snake_host_flow_test.gd` |

## Engine modules

| Path | Notes |
|------|-------|
| `engine/fixed_tick.gd` | `FixedTick.SEC` fixed step |
| `engine/seeded_rng.gd` | `SeededRng` seeded RNG wrapper |
| `engine/input_state.gd` | `InputState` held/edge actions |
| `engine/high_score_table.gd` | Fixed-capacity descending scores |
| `engine/score_store.gd` | Load/save high-score text files |
| `engine/null_audio.gd` | Headless no-op audio port |
| `engine/scene_request.gd` | `SceneRequest` PUSH/POP/REPLACE/QUIT |
| `engine/scene_stack.gd` | `SceneStack` request queue + apply + `paths()` |

## Tests

| Suite | Covers |
|-------|--------|
| `tests/engine/fixed_tick_test.gd` | `FixedTick.SEC` |
| `tests/engine/seeded_rng_test.gd` | same-seed / different-seed |
| `tests/engine/input_state_test.gd` | `InputState` held/edges/axis |
| `tests/engine/high_score_table_test.gd` | insert / qualifies / ties |
| `tests/engine/score_store_test.gd` | load/save / corrupt / missing |
| `tests/engine/null_audio_test.gd` | `NullAudio` + `AudioSpy` |
| `tests/engine/scene_stack_test.gd` | `SceneStack` apply + `paths()` |
| `tests/mocks/audio_spy.gd` | Records `play` calls for GUT |
| `tests/lab/lab_host_flow_test.gd` | launcher ↔ pong host nesting |
| `tests/games/pong/pong_sim_test.gd` | sim determinism / AI / scoring |
| `tests/games/pong/pong_host_flow_test.gd` | pause keep-alive |
| `tests/games/snake/snake_sim_test.gd` | snake rules / determinism |
| `tests/games/snake/snake_host_flow_test.gd` | snake pause keep-alive |
