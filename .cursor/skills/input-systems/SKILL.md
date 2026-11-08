---
name: input-systems
description: >-
  Map InputMap actions into engine InputState and sim commands — buffering and
  coyote in sim ticks, rebinding via LabSettings. Use when adding controls,
  remapping, gamepad support, input buffer, or edge-vs-held bugs.
---

# Input systems

Owner: raw Input → `engine/input_state.gd` in app; buffering windows counted in
**sim ticks** (`FixedTick`), not wall-clock.

Adapted from awesome-gamedev-agent-skills (`input-systems`), Apache-2.0;
rewritten for godot-game Headless First.

## When to use / not

- Use for action maps, rebind UI, deadzones, jump buffer/coyote as sim rules.
- Not for camera look math alone → `camera-systems`. Persist binds →
  `save-systems` / `LabSettings`.

## Workflow

1. Gameplay reads named actions, never raw `KEY_SPACE`.
2. App samples Godot `Input` each frame into `InputState` (begin_frame + set_action).
3. Translate edges/held into sim commands once per tick.
4. Buffer/coyote timers decrement by tick count inside sim.
5. Rebind with conflict checks; store via settings; reset to project defaults.

## Patterns

### InputState

```gdscript
_input.begin_frame()
_input.set_action(&"jump", Input.is_action_pressed("jump"))
if _input.is_action_just_pressed(&"jump"):
	_sim.try_jump()
```

Reference: `engine/input_state.gd`, `docs/reference/engine-input.md`.

### Buffer in sim ticks

```gdscript
# Inside sim — not Time.get_ticks_msec
if jump_pressed:
	_jump_buffer_ticks = 8
_jump_buffer_ticks = maxi(_jump_buffer_ticks - 1, 0)
```

## Pitfalls

- Buffer in seconds via wall-clock → nondeterministic / Headless First break.
- Held check for jump → re-fire every frame.
- Per-axis deadzone → use radial / `Input.get_vector`.

## Verify

`tests/engine/input_state_test.gd` + game command tests.

## Docs to update

`docs/reference/engine-input.md`, game app reference for bindings.
