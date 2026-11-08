---
title: Gridward plan 11 — campaign and save
diataxis: how-to
audience: [ai, human]
related_code:
  - games/gridward/sim/
  - games/gridward/app/
  - tests/games/gridward/
related_docs:
  - 07-bot-harness.md
  - 09-hud-ux.md
  - 12-polish-ship.md
  - ../spec.md
keywords: [gridward, campaign, stars, save]
last_reviewed: 2026-11-08
---

# 11 — Campaign and save

## Goal

Five maps, three difficulties, stars, unlocks, map select + results, versioned
progress save. Success: round-trip GUT; unlock gate enforced.

## Prerequisites

- [07-bot-harness.md](07-bot-harness.md) (sim complete enough)
- [09-hud-ux.md](09-hud-ux.md) (play shell)

## Scope

**In:** catalogs for maps 2–5; `map_select`, `results`; `GridwardProgress` + store; difficulties.  
**Out:** endless mode, cloud sync.

## Files

| Path | Action |
|------|--------|
| `games/gridward/sim/gridward_catalog.gd` | maps 2–5 builders |
| `games/gridward/sim/gridward_progress.gd` | plain data |
| `games/gridward/app/progress_store.gd` | FileAccess IO (app) |
| `games/gridward/app/map_select.gd` / `.tscn` | add |
| `games/gridward/app/results.gd` / `.tscn` | add |
| `games/gridward/app/menu.gd` | → map select |
| `tests/games/gridward/gridward_progress_test.gd` | add |
| `tests/games/gridward/gridward_campaign_test.gd` | unlock / stars |

## API sketch

```gdscript
class_name GridwardProgress
extends RefCounted
var version: int = 1
var cleared: Dictionary  # map_id -> {easy, normal, hard} star counts
func stars_for(map_id: StringName, diff: StringName) -> int
func is_unlocked(map_id: StringName) -> bool
func capture_state() -> Dictionary
func apply_state(data: Dictionary) -> void
```

IO in app only; migrate while `version < CURRENT`.

## GUT

- `test_progress_round_trip`
- `test_migrate_v1_noop`
- `test_citadel_locked_until_bastion_cleared`
- `test_stars_from_lives_thresholds`

## Docs

`explanation/flow.md` campaign sequence; `reference/sim.md` difficulties; update index.

## Skills

`save-systems`, `sim-data-resources`, `level-design`, `game-ui-ux`

## Verify

```sh
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/games/gridward
```

## Todos / commits

1. Maps 2–5 + difficulties → `Author Gridward campaign maps and difficulty modifiers.`
2. Progress store + UI → `Add Gridward progress save, map select, and results.`
