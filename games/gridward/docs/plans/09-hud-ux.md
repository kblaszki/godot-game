---
title: Gridward plan 09 — HUD and UX
diataxis: how-to
audience: [ai, human]
related_code:
  - games/gridward/app/
  - tests/games/gridward/
related_docs:
  - 08-board-3d.md
  - 10-juice-audio.md
  - ../spec.md
keywords: [gridward, HUD, pause, build-bar]
last_reviewed: 2026-11-08
---

# 09 — HUD and UX

## Goal

Playable desktop loop: build bar, tower panel, wave preview, start wave, speed
toggle, pause. Success: host_flow covers menu→play→pause→back.

## Prerequisites

- [08-board-3d.md](08-board-3d.md)

## Scope

**In:** play HUD, pause_menu, input→sim commands, 1×/2× stepping.  
**Out:** campaign map select (11), juice particles, pxl icons (10 can stub labels).

## Files

| Path | Action |
|------|--------|
| `games/gridward/app/play.gd` / `.tscn` | HUD docks |
| `games/gridward/app/pause_menu.gd` / `.tscn` | add |
| `games/gridward/app/host.gd` | wire sim tick from play |
| `tests/games/gridward/gridward_host_flow_test.gd` | extend |

## API sketch

```gdscript
# play.gd
func _process(delta):
	# if not paused: sim.step(); if speed2x: sim.step()
func _on_build_pressed(tower_id: StringName) -> void
func _on_start_wave() -> void
```

Corner HUD pattern: Districts `play.tscn`. Focus: grab on pause open.

## GUT

- `test_play_should_place_tower_via_sim_api`
- `test_pause_should_push_and_resume_pop`
- `test_speed_toggle_should_double_steps_per_frame` (count steps with stub)

## Docs

`reference/app.md` HUD map; `explanation/flow.md` app sequence.

## Skills

`game-ui-ux`, `input-systems`, `godot-app-scripting`

## Verify

```sh
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/games/gridward
```

## Todos / commits

1. Play HUD + commands → `Wire Gridward play HUD to sim commands.`
2. Pause + host_flow → `Add Gridward pause menu and host flow coverage.`
