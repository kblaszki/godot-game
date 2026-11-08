---
name: procedural-gen
description: >-
  Generate sim content with SeededRng — noise, dungeon rooms/corridors, WFC,
  weighted loot — into plain data grids first, with reachability checks and
  same-seed GUT. Use when the user mentions procedural, seed, dungeon, Perlin,
  loot table, or daily challenge generation.
---

# Procedural generation (sim)

Owner: `games/<game>/sim/` as `RefCounted` generators. App paints the resulting
data (`TileMapLayer`, meshes). Never call global `rand*` in generation.

Adapted from awesome-gamedev-agent-skills (`procedural-gen`), Apache-2.0;
rewritten for godot-game Headless First.

## When to use / not

- Use for maps, loot, spawns, or any content reproducible from a seed.
- Not for hand-paced authored levels alone → `level-design`. Painting tiles →
  `godot-2d-presentation`.

## Workflow

1. Own one `SeededRng` instance; thread it through every random choice.
2. Generate into plain arrays/dicts first; a separate app pass draws.
3. Validate (reachability, spawn safe, exit exists); reject or repair.
4. Tune with a fixed seed, then seed-sweep in GUT.
5. Pin first N RNG outputs in a test if shared seeds must survive refactors.

## Patterns

### SeededRng only

```gdscript
func generate(seed: int) -> Dictionary:
	var rng := SeededRng.new(seed)
	var room_count := rng.randi_range(5, 12)
	# ... fill grid using only rng.*
	return {"grid": grid, "seed": seed}
```

### Weighted pick

```gdscript
func weighted_pick(rng: SeededRng, items: Array, weights: Array) -> Variant:
	var total := 0.0
	for w in weights:
		total += float(w)
	var roll := rng.randf() * total
	var upto := 0.0
	for i in items.size():
		upto += float(weights[i])
		if roll < upto:
			return items[i]
	return items[items.size() - 1]
```

### Connectivity

Flood-fill from spawn; discard or reconnect unreachable cells before return.

## Pitfalls

- Global `RandomNumberGenerator` / `randf()` → unreproducible.
- Correlated noise fields from one seed/offset → offset each field.
- No connectivity check → soft-locked maps.
- Saving only the seed across Godot RNG version changes → pin a custom PRNG
  or save the generated result.

## Verify

Same seed → identical grid; two seeds differ; invalid layouts rejected.

```sh
godot --path . --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/games/<name>
```

## Docs to update

`games/<game>/docs/reference/sim.md`, explanation Mermaid for gen → play flow.
