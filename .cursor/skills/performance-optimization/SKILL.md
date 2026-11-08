---
name: performance-optimization
description: >-
  Profile first, then fix bottlenecks — app draw calls/pooling, sim tick
  budgets measured in headless GUT by work-per-tick (not wall-clock in sim).
  Use when FPS drops, stutter, GC spikes, draw-call explosions, or slow bots.
---

# Performance optimization

Owner: measure in editor/release builds for app; for sim, assert work bounds in
GUT (iterations, cells visited) — never `Time.get_ticks_*` inside sim code.

Adapted from awesome-gamedev-agent-skills (`performance-optimization`),
Apache-2.0; rewritten for godot-game Headless First.

## When to use / not

- Use when frames miss budget or a sim step does too much work.
- Not for physics feel bugs → `sim-physics`. Early prototype → don't micro-opt.

## Workflow

1. State target (60 FPS ≈ 16.7 ms) and a reproducible worst scene.
2. Profile: Godot Debugger Profiler / Visual Profiler / Monitors.
3. CPU vs GPU: fix the side that dominates.
4. Sim: reduce algorithmic work; GUT can count ticks/ops for a fixed scenario.
5. App: pool nodes, atlas/batch, MultiMesh, fewer unique materials.
6. Re-measure; report before/after numbers.

## Patterns

### Sim budget in GUT

```gdscript
var ops := 0
sim.run_with_op_counter(func(): ops += 1)
assert_lt(ops, 10_000)
```

Do not call wall-clock from sim; the test harness may time the suite externally.

### Pool in app

```gdscript
func acquire() -> Node3D:
	var n: Node3D = _pool.pop_back() if not _pool.is_empty() else scene.instantiate()
	n.visible = true
	return n
```

## Pitfalls

- Optimizing without a profile → wrong target.
- Instantiating every SFX/bullet → pool.
- Measuring only the editor → prefer export/release when it matters.

## Verify

Profiler numbers + GUT op/tick caps. Docs: note budgets in app/sim references.
