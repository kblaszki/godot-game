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
| `project.godot` | Godot 4.x project (single lab); GUT plugin enabled |
| `AGENTS.md` | Tool-neutral agent summary |
| `engine/` | Shared headless GDScript libraries |
| `engine/empty_boot.tscn` | Temporary main scene until a game host is wired |
| `games/` | Per-game `sim/`, `app/`, `docs/` (none yet) |
| `tests/engine/` | GUT suites for `engine/` (`*_test.gd`) |
| `tests/games/` | Per-game GUT suites |
| `docs/` | Cross-game Diátaxis docs |
| `addons/gut/` | GUT **9.3.1** (vendored, plugin enabled) |
| `.cursor/rules/` | Cursor rules |
| `.cursor/skills/` | Cursor skills |

## Games

| Game | sim | app | docs | tests |
|------|-----|-----|------|-------|
| _(none yet)_ | — | — | — | — |

## Engine modules

| Path | Notes |
|------|-------|
| `engine/fixed_tick.gd` | `FixedTick.SEC` fixed step |
| `engine/seeded_rng.gd` | `SeededRng` seeded RNG wrapper |
| `engine/scene_request.gd` | `SceneRequest` PUSH/POP/REPLACE/QUIT |
| `engine/scene_stack.gd` | `SceneStack` request queue + apply |
| `engine/empty_boot.tscn` | Temporary main scene |

## Engine tests

| Suite | Covers |
|-------|--------|
| `tests/engine/fixed_tick_test.gd` | `FixedTick.SEC` |
| `tests/engine/seeded_rng_test.gd` | same-seed / different-seed |
| `tests/engine/scene_stack_test.gd` | `SceneStack` apply batch |
