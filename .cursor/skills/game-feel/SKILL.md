---
name: game-feel
description: >-
  Add juice on top of sim events — camera trauma shake, hit-stop by skipping
  sim steps, Tween easing, squash/stretch, feedback tiers — without mutating
  sim rules. Use when hits feel weak, need screen shake, freeze frames, or
  punchy UI/mesh feedback.
---

# Game feel (juice)

Owner: `games/<game>/app/` (and thin host timing). Sim emits events; juice reacts.

Adapted from awesome-gamedev-agent-skills (`game-feel`, `godot-animation`),
Apache-2.0; rewritten for godot-game Headless First.

## When to use / not

- Use after mechanics work but feel flat (putt hit, buy, brick break).
- Not for controller math → sim / genre. Camera framing → `camera-systems`.

## Workflow

1. Confirm sim emits discrete events (`on_hit`, `on_sink`, phase changes).
2. Layer 2–3 channels first (SFX, shake, tween); scale by importance tier.
3. Shake camera offset only — never the simulated body transform.
4. Hit-stop: host skips N sim ticks (or pauses applying steps); **do not** set
   `Engine.time_scale` inside sim.
5. Tweens use eased transitions (`TRANS_BACK` for pop); return to rest.

## Patterns

### Trauma shake (camera)

```gdscript
func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)

func _process(dt: float) -> void:
	trauma = maxf(trauma - decay * dt, 0.0)
	var shake := trauma * trauma
	offset = Vector2(max_offset.x * shake * sin(_t * 1.7),
			max_offset.y * shake * sin(_t * 2.3))
```

### Hit-stop without breaking sim

```gdscript
# In play host — freeze presentation / withhold sim.step for N frames
_hit_stop_frames = 4
```

### Event → tier bundle

Map sim events to small/medium/large presets (audio + trauma + particles).

## Pitfalls

- `Engine.time_scale` as global feel → desyncs FixedTick determinism expectations.
- Random offset every frame → buzz; use decaying trauma + sin/noise.
- Juice blocking input for long → keep short; buffer through freezes.

## Verify

Manual play + ensure GUT still deterministic (juice must not feed RNG into sim).

## Docs to update

`games/<game>/docs/reference/app.md`.
