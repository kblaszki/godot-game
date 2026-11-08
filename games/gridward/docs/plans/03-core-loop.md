---
title: Gridward plan 03 — core loop
diataxis: how-to
audience: [ai, human]
related_code:
  - games/gridward/sim/gridward_sim.gd
  - tests/games/gridward/
related_docs:
  - 02-data-model.md
  - 04-towers.md
  - ../spec.md
keywords: [gridward, waves, pathing, FixedTick]
last_reviewed: 2026-11-08
---

# 03 — Core loop

## Goal

Headless match without towers: spawn, path with leftover distance, leaks, wave
clear, victory/defeat. Success: same-seed determinism GUT green.

## Prerequisites

- [02-data-model.md](02-data-model.md)

## Scope

**In:** `GridwardSim` phases build/wave/wave_clear/victory/defeat; `start_wave`, `step`, `drain_events`; enemy movement.  
**Out:** tower combat (stub empty acquire), upgrades, bot, app.

## Files

| Path | Action |
|------|--------|
| `games/gridward/sim/enemy_state.gd` | add |
| `games/gridward/sim/gridward_sim.gd` | add |
| `games/gridward/sim/gridward_events.gd` | optional event helpers |
| `tests/games/gridward/gridward_sim_test.gd` | add |
| `games/gridward/docs/explanation/flow.md` | stateDiagram from spec |
| `games/gridward/docs/reference/sim.md` | API section |

## API sketch

```gdscript
class_name GridwardSim
extends RefCounted
enum Phase { BUILD, WAVE, WAVE_CLEAR, VICTORY, DEFEAT }
func _init(map: MapDef, catalog: GridwardCatalog, seed: int) -> void: ...
func get_phase() -> int: ...
func get_gold() -> int: ...
func get_lives() -> int: ...
func get_wave_index() -> int: ...
func start_wave() -> bool: ...
func step() -> void: ...
func drain_events() -> Array: ...
func get_enemies() -> Array: ...
```

Pathing: advance along polyline; when segment ends, carry leftover distance into next segment (spec §3).

## GUT

- `test_start_wave_should_enter_wave_phase`
- `test_enemy_should_follow_waypoints_without_stalling`
- `test_leak_should_decrement_lives_and_remove_enemy`
- `test_clearing_last_wave_should_victory`
- `test_lives_zero_should_defeat`
- `test_same_seed_should_match_enemy_positions_after_n_steps`

## Docs

`explanation/flow.md` Mermaid `stateDiagram-v2`; sequence snippet optional.

## Skills

`sim-physics` (path integration habits), `sim-data-resources`, `run-build-and-tests`

## Verify

```sh
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/games/gridward
```

## Todos / commits

1. EnemyState + path follow → `Add Gridward enemy path following on FixedTick.`
2. Phases + determinism tests → `Implement Gridward wave phases with determinism GUT.`
