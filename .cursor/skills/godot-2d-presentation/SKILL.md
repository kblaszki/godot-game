---
name: godot-2d-presentation
description: >-
  Present 2D sim grids and motion with TileMapLayer, _draw, or kinematic
  mirrors — CharacterBody2D only follows sim, never owns rules. Use when
  rendering tile maps, sprites from board state, or 2D play views.
---

# Godot 2D presentation

Owner: `games/<game>/app/`. Sim grid/positions are truth; Nodes mirror.

Adapted from awesome-gamedev-agent-skills (`godot-2d-movement`, `godot-tilemap`),
Apache-2.0; rewritten for godot-game Headless First / Godot **4.3**.

## When to use / not

- Use for Snake/Pong/Breakout-style views, tile painting from generated grids.
- Not for jump coyote as Node logic → sim + `input-systems`. 3D →
  `godot-3d-presentation`.

## Workflow

1. Paint from a plain grid/array produced by sim or `procedural-gen`.
2. Prefer `TileMapLayer` (4.x) over legacy single TileMap where practical.
3. If using `CharacterBody2D`, set position from sim each tick — do not
   `move_and_slide` as the rule source.
4. Camera follow → `camera-systems`.
5. GUT tests sim; app host_flow covers scene wiring.

## Patterns

### Mirror position

```gdscript
func _process(_dt: float) -> void:
	$Ball.position = _sim.ball_position  # pixels / world units agreed with sim
```

### Tile from data

```gdscript
for y in h:
	for x in w:
		layer.set_cell(Vector2i(x, y), source_id, atlas_coords_for(grid[y][x]))
```

## Pitfalls

- Implementing gravity in `_physics_process` while a sim also integrates → desync.
- Editing tiles by hand in editor as the only level source → prefer catalog data
  (`level-design` / `sim-data-resources`).

## Verify

Game `host_flow` GUT; docs `games/<game>/docs/reference/app.md`.
