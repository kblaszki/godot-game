---
title: Gridward plan 02 — data model
diataxis: how-to
audience: [ai, human]
related_code:
  - games/gridward/sim/
  - tests/games/gridward/
related_docs:
  - 01-scaffold.md
  - 03-core-loop.md
  - ../spec.md
keywords: [gridward, MapDef, catalog, WaveDef]
last_reviewed: 2026-11-08
---

# 02 — Data model

## Goal

Typed defs and Meadow catalog injectable into the future sim. Success: validation
GUT green; no FileAccess in sim.

## Prerequisites

- [01-scaffold.md](01-scaffold.md)

## Scope

**In:** `GridwardConfig`, `MapDef`, `EnemyDef`, `TowerDef`, `WaveDef`, `GridwardCatalog.build_meadow()`.  
**Out:** runtime sim stepping, placement.

## Files

| Path | Action |
|------|--------|
| `games/gridward/sim/gridward_config.gd` | add |
| `games/gridward/sim/map_def.gd` | add |
| `games/gridward/sim/enemy_def.gd` | add |
| `games/gridward/sim/tower_def.gd` | add |
| `games/gridward/sim/wave_def.gd` | add |
| `games/gridward/sim/gridward_catalog.gd` | add |
| `tests/games/gridward/gridward_catalog_test.gd` | add |
| `games/gridward/docs/reference/sim.md` | document types |

## API sketch

```gdscript
class_name MapDef
extends RefCounted
var id: StringName
var width: int
var height: int
var buildable: PackedByteArray  # width*height, 0/1
var waypoints: PackedVector2Array  # cell centers or cell indices as Vector2
var starting_gold: int
var starting_lives: int
var waves: Array  # WaveDef

class_name WaveDef
extends RefCounted
var entries: Array  # {enemy_id, count, spacing_ticks, delay_ticks}

class_name GridwardCatalog
extends RefCounted
static func build_meadow() -> MapDef: ...
static func enemy(id: StringName) -> EnemyDef: ...
static func tower(id: StringName) -> TowerDef: ...
```

Meadow: 16×10, S-curve waypoints, bolt unlocked, 10 waves of grunt/runner only.

## GUT

- `test_meadow_path_cells_should_stay_in_bounds`
- `test_buildable_should_not_overlap_path`
- `test_waves_should_reference_known_enemies`
- `test_tower_and_enemy_tables_should_match_spec_ids`

## Docs

`reference/sim.md` class list + Mermaid ownership; update [spec.md](../spec.md) related_code if needed.

## Skills

`sim-data-resources`, `level-design`, `add-entity`

## Verify

```sh
godot --path . --headless --import
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/games/gridward
```

## Todos / commits

1. Def types → `Add Gridward MapDef and entity resource types.`
2. Catalog + GUT → `Add Meadow catalog with validation tests.`
