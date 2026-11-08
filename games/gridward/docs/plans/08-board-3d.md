---
title: Gridward plan 08 — board 3D
diataxis: how-to
audience: [ai, human]
related_code:
  - games/gridward/app/board_3d.gd
  - games/gridward/app/board_3d.tscn
  - tests/games/gridward/
related_docs:
  - 03-core-loop.md
  - 09-hud-ux.md
  - ../spec.md
keywords: [gridward, Board3D, camera, raycast]
last_reviewed: 2026-11-08
---

# 08 — Board 3D

## Goal

Present grid, path, towers, enemies in a SubViewport world; camera orbit/pan/fit;
cell pick with placement ghost. Success: pure helper GUT; meshes skipped headless.

## Prerequisites

- [03-core-loop.md](03-core-loop.md) (sim state to mirror). Towers from 04 improve visuals but path/enemies enough to start.

## Scope

**In:** `board_3d`, camera, ray→cell, ghost, sync from sim snapshot.  
**Out:** full HUD docks, juice VFX, icons.

## Files

| Path | Action |
|------|--------|
| `games/gridward/app/board_3d.gd` / `.tscn` | add |
| `games/gridward/app/play.gd` / `.tscn` | embed board |
| `tests/games/gridward/gridward_board3d_test.gd` | yaw/cell helpers |

## API sketch

```gdscript
# board_3d.gd
func sync_from_sim(sim: GridwardSim) -> void
func cell_at_screen(pos: Vector2) -> Vector2i  # INF sentinel on miss
func set_ghost(cell: Vector2i, ok: bool) -> void
func get_camera() -> Camera3D
static func cell_to_world(cell: Vector2i) -> Vector3
```

Follow Fairway `course_3d.gd` / Districts `board_3d.gd`: skip MeshInstance when headless.

## GUT

- `test_cell_to_world_should_center_on_cell`
- `test_world_to_cell_roundtrip`
- Headless instantiate sync without errors

## Docs

`reference/app.md` Board3D section + Mermaid app mirrors sim.

## Skills

`godot-3d-presentation`, `camera-systems`, `godot-app-scripting`

## Verify

```sh
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/games/gridward
```

## Todos / commits

1. Board meshes + sync → `Present Gridward board state in Board3D.`
2. Camera + pick + tests → `Add Gridward orbit camera and cell picking helpers.`
