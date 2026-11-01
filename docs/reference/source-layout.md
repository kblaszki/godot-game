---
title: Source layout
diataxis: reference
audience: [ai, human]
related_code: [project.godot, engine/, games/, tests/, docs/, AGENTS.md, addons/gut/]
related_docs:
  - ../index.md
  - ../explanation/architecture.md
  - engine-core.md
  - engine-scene-stack.md
keywords: [layout, inventory, paths, tests]
last_reviewed: 2026-11-01
---

# Source layout

Inventory of the lab tree. Update this page when paths are added, removed, or renamed.

## Root

| Path | Role |
|------|------|
| `project.godot` | Godot 4.x project (single lab); GUT plugin enabled; `run/main_scene` is `res://games/pong/app/host.tscn` |
| `AGENTS.md` | Tool-neutral agent summary |
| `engine/` | Shared headless GDScript libraries |
| `engine/empty_boot.tscn` | Placeholder scene. `run/main_scene` is the pong host |
| `games/` | Per-game `sim/`, `app/`, `docs/` |
| `tests/engine/` | GUT suites for `engine/` (`*_test.gd`) |
| `tests/games/` | Per-game GUT suites |
| `docs/` | Cross-game Diátaxis docs |
| `addons/gut/` | GUT **9.3.1** (vendored, plugin enabled) |
| `.cursor/rules/` | Cursor rules |
| `.cursor/skills/` | Cursor skills |

## Games

| Game | sim | app | docs | tests |
|------|-----|-----|------|-------|
| pong | `games/pong/sim/pong_config.gd`, `games/pong/sim/pong_sim.gd` | `games/pong/app/host.gd`, `games/pong/app/host.tscn`, `games/pong/app/main_menu.gd`, `games/pong/app/main_menu.tscn`, `games/pong/app/play.gd`, `games/pong/app/play.tscn` (`host.tscn` is `run/main_scene`) | `games/pong/docs/` | `tests/games/pong/pong_sim_test.gd` |

## Engine modules

| Path | Notes |
|------|-------|
| `engine/fixed_tick.gd` | `FixedTick.SEC` fixed step |
| `engine/seeded_rng.gd` | `SeededRng` seeded RNG wrapper |
| `engine/scene_request.gd` | `SceneRequest` PUSH/POP/REPLACE/QUIT |
| `engine/scene_stack.gd` | `SceneStack` request queue + apply |
| `engine/empty_boot.tscn` | Placeholder scene. `run/main_scene` is the pong host |

## Engine tests

| Suite | Covers |
|-------|--------|
| `tests/engine/fixed_tick_test.gd` | `FixedTick.SEC` |
| `tests/engine/seeded_rng_test.gd` | same-seed / different-seed |
| `tests/engine/scene_stack_test.gd` | `SceneStack` apply batch |
