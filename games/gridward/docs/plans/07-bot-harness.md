---
title: Gridward plan 07 — bot harness
diataxis: how-to
audience: [ai, human]
related_code:
  - games/gridward/sim/gridward_bot.gd
  - tests/games/gridward/
related_docs:
  - 06-enemy-roster.md
  - 11-campaign-save.md
  - ../spec.md
keywords: [gridward, bot, utility, balance]
last_reviewed: 2026-11-08
---

# 07 — Bot harness

## Goal

Headless bot that plays Meadow on Normal to victory through the public sim API.
Success: `test_bot_should_clear_meadow_normal` green; optional seed sweep.

## Prerequisites

- [06-enemy-roster.md](06-enemy-roster.md)

## Scope

**In:** `GridwardBot` utility placement/upgrades/early-call heuristics; GUT clear + seed sweep.  
**Out:** app AI visualization, difficulty scaling for bot.

## Files

| Path | Action |
|------|--------|
| `games/gridward/sim/gridward_bot.gd` | add |
| `tests/games/gridward/gridward_bot_test.gd` | add |

## API sketch

```gdscript
class_name GridwardBot
extends RefCounted
func _init(sim: GridwardSim, catalog: GridwardCatalog) -> void: ...
func act() -> void:
	# score buildable cells × tower types; place/upgrade/start_wave via sim only
	pass
```

Scoring hints: prefer cells maximizing path length in range; buy bolt early;
upgrade when gold > 1.5× next cost; start wave when idle and defenses ≥ threshold.

## GUT

- `test_bot_should_clear_meadow_normal` (cap steps e.g. 60fps×20min ticks)
- `test_bot_same_seed_should_be_deterministic`
- `test_bot_seed_sweep_should_not_softlock` (seeds 1..10, assert not stuck in BUILD forever)

## Docs

`reference/sim.md` bot section; note as balance canary in `balance.md`.

## Skills

`sim-bot-ai`, `performance-optimization` (tick budgets if slow)

## Verify

```sh
godot --path . --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/games/gridward -gprefix=gridward_bot
```

## Todos / commits

1. Bot utility + clear test → `Add GridwardBot that clears Meadow in GUT.`
2. Determinism + seed sweep → `Harden GridwardBot with seed-sweep balance checks.`
