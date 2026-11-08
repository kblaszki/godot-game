---
name: godot-3d-presentation
description: >-
  Present sim state in Godot 4.3 3D — SubViewport + Node3D, Camera3D, lights,
  WorldEnvironment, procedural meshes — skipping mesh work when headless.
  Use when building Course3D/Board3D, 3D cameras, materials, or fixing wall/yaw
  mesh orientation.
---

# Godot 3D presentation

Owner: `games/<game>/app/` (e.g. `course_3d.gd`, `board_3d.gd`). Sim stays
authoritative for positions; meshes mirror.

Adapted from awesome-gamedev-agent-skills (`godot-3d-essentials`), Apache-2.0;
rewritten for godot-game Headless First / Godot **4.3**.

## When to use / not

- Use for 3D boards, courses, lighting, environment, MeshInstance3D.
- Not for physics rules → `sim-physics`. Orbit feel → `camera-systems`.
- No `AreaLight3D` (not in 4.3). Prefer Directional/Omni/Spot.

## Workflow

1. Embed world in `SubViewport` under a Control host when the lab UI surrounds it.
2. Skip creating meshes when `DisplayServer.get_name() == "headless"`.
3. Lights + `WorldEnvironment` or surfaces render black.
4. Orient horizontal segments with yaw `atan2(-delta.y, delta.x)` for XZ deltas.
5. GUT covers pure helpers (yaw, fit); visual smoke is manual/windowed.

## Patterns

### Headless-safe mesh

```gdscript
var _use_meshes := DisplayServer.get_name() != "headless"
if _use_meshes:
	_ball = MeshInstance3D.new()
	# ...
```

### Wall / arrow yaw (lab convention)

```gdscript
static func yaw_for_xz_delta(delta: Vector2) -> float:
	return atan2(-delta.y, delta.x)
```

Wrong `atan2(delta.x, delta.y)` drew Fairway Circuit walls diagonally.

### Sun + env

`DirectionalLight3D.shadow_enabled = true`; ProceduralSky + filmic tonemap.

## Pitfalls

- Rules on MeshInstance transforms → dual truth; read sim each frame.
- Scaling non-uniform on physics cosmetics → odd shadows; keep uniform.
- `look_at` with parallel up → error; keep pitch away from ±90°.

## Verify

`tests/games/minigolf/` course3d yaw tests; docs `games/<game>/docs/reference/app.md`.
