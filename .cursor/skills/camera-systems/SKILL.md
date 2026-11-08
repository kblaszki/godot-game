---
name: camera-systems
description: >-
  Build app cameras that feel good — exponential smoothing, deadzone,
  look-ahead, 3D orbit/pan/dolly/fit, ViewFit — consuming sim focus points.
  Use when adding follow cameras, orbit rigs, fit framing, or fixing camera
  jitter and bounds.
---

# Camera systems

Owner: `games/<game>/app/` camera helpers; shared fit math in `engine/view_fit.gd`.
Shake triggers → `game-feel` (offset hook only here).

Adapted from awesome-gamedev-agent-skills (`camera-systems`), Apache-2.0;
rewritten for godot-game Headless First.

## When to use / not

- Use for 2D follow, 3D orbit (Fairway Circuit / Districts), fit-to-content.
- Not for trauma magnitude → `game-feel`. Not for sim positions of the subject.

## Workflow

1. Smooth with `1.0 - exp(-rate * dt)`, never bare `lerp(..., 0.1)`.
2. Update after the subject moves (post-sim apply in the host frame).
3. 3D: yaw/pitch on a pivot; clamp pitch; separate pan/dolly from orbit.
4. Compose: follow → then add shake offset.
5. Unit-test pure helpers (`ViewFit.compute`, yaw, fit bias).

## Patterns

### Exponential follow

```gdscript
var t := 1.0 - exp(-rate * dt)
global_position = global_position.lerp(target, t)
```

### Lab 3D orbit / fit

Reference: `games/minigolf/app/course_3d.gd` — LMB orbit, RMB/MMB pan, F fit
biased toward tee; accessors `get_camera()`, `is_orbiting()`, `is_panning()`.

### ViewFit

```gdscript
var fit := ViewFit.compute(content_size, viewport_size)
# scale + centered offset
```

## Pitfalls

- Frame-rate-dependent lerp constant → different feel at 30 vs 144 FPS.
- Shake driving the follow target → fight; additive offset last.
- Fit ignoring playable bounds → tee/cup off-screen; bias focus deliberately.

## Verify

`tests/engine/view_fit_test.gd`; game course3d/board tests. Docs: app reference.
