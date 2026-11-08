---
name: sim-physics
description: >-
  Build headless fixed-tick physics in games/<game>/sim/ — SeededRng-free
  integrators, substeps, swept collision against tunneling, restitution and
  friction as config. Use when adding ball/body motion, collision feel,
  tunneling, jitter, or when Godot RigidBody would otherwise own game rules.
---

# Sim physics (Headless First)

Owner: `games/<game>/sim/` (`RefCounted`). App may mirror with Godot bodies for
cosmetics only — rules never live on `CharacterBody*` / `RigidBody*`.

Adapted from awesome-gamedev-agent-skills (`physics-tuning`, `godot-physics`),
Apache-2.0; rewritten for godot-game Headless First.

## When to use / not

- Use for putt-putt, projectiles, board tokens with continuous motion, or any
  mechanic that needs stable collision independent of frame rate.
- Not for engine RigidBody setup as the rule source → keep that in app cosmetics
  only. Jump coyote/buffer → `input-systems` + genre playbook.

## Workflow

1. Integrate with `FixedTick.SEC` (or an explicit substep of it). Never wall-clock.
2. Put positions/velocities in sim state; emit events the app juices.
3. Prefer swept segment vs AABB/circle for fast thin walls (tunneling).
4. Cap speed so one step cannot skip a wall thickness; substep if needed.
5. Restitution/friction/damping live in config (`MinigolfConfig`-style).
6. GUT: same-seed trajectories match; wall hit does not tunnel; determinism check.

## Patterns

### Fixed-tick integrate + substep

```gdscript
# Inside MinigolfSim / similar — no Node, no Engine.time_scale.
const SUBSTEPS := 4

func _integrate_moving() -> void:
	var dt := FixedTick.SEC / float(SUBSTEPS)
	for _i in SUBSTEPS:
		_ball.position += _ball.velocity * dt
		_resolve_walls(_ball)   # swept or discrete against authored segments
		_apply_friction(_ball, dt)
```

Reference: `games/minigolf/sim/` ball integrator and wall segments.

### Tunneling guard

- Max distance per substep < thinnest wall.
- Prefer ray/segment intersection against wall segments over discrete point-in.

### App mirror (optional)

App `Course3D` / `Board3D` draws meshes; it does not call `move_and_slide` as truth.

## Pitfalls

- Rules in `_physics_process` → frame-rate dependent; move into sim tick.
- Unseeded bounce RNG → non-deterministic tests; use `SeededRng` only if random.
- Hit-stop via `Engine.time_scale` inside sim → forbidden; host skips N sim steps
  (see `game-feel`).
- Godot CCD on a RigidBody as the only collision → dual sources of truth.

## Verify

```sh
godot --path . --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/games/<name>
```

## Docs to update

`games/<game>/docs/reference/sim.md`, architecture Mermaid if flow changes,
`docs/reference/engine-core.md` if FixedTick usage expands.
