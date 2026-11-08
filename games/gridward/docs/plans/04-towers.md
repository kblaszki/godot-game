---
title: Gridward plan 04 — towers
diataxis: how-to
audience: [ai, human]
related_code:
  - games/gridward/sim/
  - tests/games/gridward/
related_docs:
  - 03-core-loop.md
  - 05-economy-balance.md
  - ../spec.md
keywords: [gridward, towers, targeting, hitscan]
last_reviewed: 2026-11-08
---

# 04 — Towers

## Goal

Place/sell/upgrade bolt (and stub other defs), targeting modes, hitscan fire on
cooldown. Success: each targeting mode covered by GUT; gold deducted on place.

## Prerequisites

- [03-core-loop.md](03-core-loop.md)

## Scope

**In:** `place_tower`, `sell_tower`, `upgrade_tower`, `set_targeting`; bolt hitscan; mortar splash; basic projectile flight in sim ticks.  
**Out:** frost/flak/beam specials (defs may exist but behavior in 06), UI.

## Files

| Path | Action |
|------|--------|
| `games/gridward/sim/tower_state.gd` | add |
| `games/gridward/sim/projectile_state.gd` | add if needed |
| `games/gridward/sim/gridward_sim.gd` | extend |
| `tests/games/gridward/gridward_towers_test.gd` | add |

## API sketch

```gdscript
func place_tower(cell: Vector2i, tower_id: StringName) -> int:  # tower entity id or -1
func sell_tower(tower_entity_id: int) -> bool:
func upgrade_tower(tower_entity_id: int) -> bool:
func set_targeting(tower_entity_id: int, mode: StringName) -> void
```

Acquire: filter range + air rules; sort by mode; tie-break lowest id.

## GUT

- `test_place_on_path_should_fail`
- `test_place_should_spend_gold`
- `test_bolt_should_damage_first_in_range`
- `test_targeting_closest_should_pick_nearest`
- `test_mortar_splash_should_hit_neighbors`
- `test_sell_should_refund_seventy_percent`

## Docs

Update `reference/sim.md` tower API; optional Mermaid for fire sequence.

## Skills

`sim-data-resources`, `sim-physics`, `add-entity`

## Verify

```sh
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/games/gridward
```

## Todos / commits

1. Placement + bolt → `Add Gridward tower placement and bolt hitscan.`
2. Targeting + mortar + tests → `Cover targeting modes and mortar splash in GUT.`
