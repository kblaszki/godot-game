---
title: Gridward plan 06 — enemy roster
diataxis: how-to
audience: [ai, human]
related_code:
  - games/gridward/sim/
  - tests/games/gridward/
related_docs:
  - 05-economy-balance.md
  - 07-bot-harness.md
  - ../spec.md
keywords: [gridward, armor, flyer, status, burn, slow]
last_reviewed: 2026-11-08
---

# 06 — Enemy roster and statuses

## Goal

Ship full enemy set and tower specials (frost slow, flak anti-air, beam ramp,
burn if used). Success: GUT per flag/status; bolt cannot hit air.

## Prerequisites

- [05-economy-balance.md](05-economy-balance.md)

## Scope

**In:** tank armor, swarm groups, flyer, boss; frost/flak/beam behavior; slow/burn.  
**Out:** campaign maps 2–5 content (catalog stubs OK), bot.

## Files

| Path | Action |
|------|--------|
| `games/gridward/sim/status_effect.gd` | add |
| `games/gridward/sim/gridward_catalog.gd` | full enemy/tower tables |
| `games/gridward/sim/gridward_sim.gd` | engage filters + statuses |
| `tests/games/gridward/gridward_roster_test.gd` | add |

## API sketch

```gdscript
# TowerDef flags
var anti_air: bool
var ground_only: bool
# EnemyDef
var is_air: bool
var armor: int
# Sim
func _apply_damage(enemy, raw: int) -> int:  # armor, min 1
func _tick_statuses() -> void
```

## GUT

- `test_armor_should_reduce_damage_to_minimum_one`
- `test_bolt_should_ignore_flyers`
- `test_flak_should_hit_flyers`
- `test_frost_should_apply_slow_capped`
- `test_beam_ramp_should_reset_on_retarget`
- `test_swarm_wave_entry_should_spawn_count`

## Docs

Update `reference/sim.md` roster tables; sync numbers with `balance.md`.

## Skills

`sim-data-resources`, `sim-bot-ai` (prep), `level-design`

## Verify

```sh
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/games/gridward
```

## Todos / commits

1. Armor/air filters → `Add Gridward armor and anti-air targeting rules.`
2. Statuses + beam + tests → `Implement frost slow, beam ramp, and roster GUT.`
