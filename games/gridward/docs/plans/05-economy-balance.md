---
title: Gridward plan 05 — economy and balance
diataxis: how-to
audience: [ai, human]
related_code:
  - games/gridward/sim/
  - games/gridward/docs/reference/balance.md
  - tests/games/gridward/
related_docs:
  - 04-towers.md
  - 06-enemy-roster.md
  - ../spec.md
keywords: [gridward, economy, balance, lane-holds]
last_reviewed: 2026-11-08
---

# 05 — Economy and balance

## Goal

Encode bounty, wave bonus, early-call, sell, upgrade curve, and HP scale; add
lane-holds sanity GUT for Meadow. Success: balance doc + failing tests made green.

## Prerequisites

- [04-towers.md](04-towers.md)

## Scope

**In:** economy formulas from spec §7; `reference/balance.md`; wave HP scale; early-call API.  
**Out:** full roster behaviors, bot.

## Files

| Path | Action |
|------|--------|
| `games/gridward/sim/gridward_sim.gd` | economy hooks |
| `games/gridward/sim/gridward_config.gd` | tunables (refund 0.7, hp_scale 1.12) |
| `games/gridward/docs/reference/balance.md` | add |
| `tests/games/gridward/gridward_economy_test.gd` | add |
| `tests/games/gridward/gridward_lane_holds_test.gd` | add |

## API sketch

```gdscript
func can_early_call() -> bool
func early_call_bonus() -> int
# start_wave() already exists; when called from BUILD with pending timer, grant bonus
```

Lane-holds helper (pure function in sim or test): estimate DPS×time_in_range vs scaled HP.

## GUT

- `test_kill_should_add_bounty`
- `test_wave_clear_should_add_bonus`
- `test_upgrade_cost_should_follow_geometric_curve`
- `test_meadow_mid_waves_should_lane_hold_on_reference_loadout`

## Docs

`reference/balance.md` tables (copy/adjust from spec); link from `sim.md` and index.

## Skills

`level-design`, `sim-data-resources`, `update-docs`

## Verify

```sh
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/games/gridward
```

## Todos / commits

1. Economy formulas + tests → `Implement Gridward economy formulas with GUT.`
2. balance.md + lane-holds → `Add Meadow lane-holds balance checks and reference doc.`
