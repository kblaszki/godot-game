---
name: level-design
description: >-
  Author playable levels as sim catalog data — metrics, pacing beats, critical
  path, teach-then-test — with GUT checks for solvability, reachability, and
  par sanity. Use when designing holes, stages, encounters, blockouts, or
  difficulty curves for a lab game.
---

# Level design (data-first)

Owner: authored content in `games/<game>/sim/` catalogs (e.g. `CourseCatalog`,
hole defs). Greybox presentation may live in `app/` after the data validates.

Adapted from awesome-gamedev-agent-skills (`level-design`), Apache-2.0;
rewritten for godot-game Headless First.

## When to use / not

- Use for hand-authored holes/stages, pacing, gating, encounter order.
- Not for pure algorithmic maps → `procedural-gen` (complementary).

## Workflow

1. Lock player metrics from sim config (speed, jump, putt power) before geometry.
2. Author the critical path as data; optional branches off it.
3. Pace as beats (teach → test → rest → climax); one new mechanic per beat.
4. Validate: goal reachable, soft-locks absent, par/time budgets sane.
5. Greybox in app only after GUT accepts the catalog.

## Patterns

### Catalog as source of truth

Reference: `games/minigolf/sim/course_catalog.gd` + `HoleDef` — tee, cup, walls,
par. Districts board layout similarly belongs in sim config, not the `.tscn`.

### Reachability check (gate graph)

```gdscript
func goal_reachable(rooms: Dictionary, start: String, goal: String) -> bool:
	var have := {}
	var reached := {start: true}
	var changed := true
	while changed:
		changed = false
		for room in reached.keys():
			var info: Dictionary = rooms[room]
			var grant = info.get("grants")
			if grant != null and not have.has(grant):
				have[grant] = true
				changed = true
			for exit in info.get("exits", []):
				var open: bool = not exit.has("needs") or have.has(exit["needs"])
				if open and not reached.has(exit["to"]):
					reached[exit["to"]] = true
					changed = true
	return reached.has(goal)
```

### Metrics

Derive SAFE_GAP / HARD_GAP from the same constants the sim uses for motion.

## Pitfalls

- Dressing `.tscn` before data validates → expensive rework.
- Soft-lock: key only obtainable past its gate.
- Flat pacing (all climax) → teach-then-test sawtooth instead.
- Par/impossible geometry → GUT should catch before playtest.

## Verify

Per-level tests: reachable, solvable (or bot finishes), par within bounds.

## Docs to update

`games/<game>/docs/reference/sim.md`, `explanation/flow.md` for stage order.
