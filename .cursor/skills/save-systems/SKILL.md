---
name: save-systems
description: >-
  Persist lab/game state with versioned schemas, atomic writes, and migration —
  build on SettingsStore/ScoreStore patterns; keep FileAccess out of sim.
  Use when adding save slots, autosave, high scores, settings migration, or
  crash-safe user:// writes.
---

# Save systems

Owner: serialization helpers under `engine/` or `games/<name>/app/` (IO boundary).
Sim exposes `capture_state()` / `apply_state()` as plain data — no `FileAccess`.

Adapted from awesome-gamedev-agent-skills (`save-systems`), Apache-2.0;
rewritten for godot-game Headless First.

## When to use / not

- Use for settings, high scores, run progress, seeded daily puzzles.
- Not for dialogue content defs → `sim-data-resources`. Online authority →
  `sim-networking`.

## Workflow

1. Save plain Dictionaries / text schemas with a `version` field from v1.
2. Atomic write: temp → rename (see `SettingsStore.save`).
3. Load: parse → migrate while `v < CURRENT` → validate → apply.
4. Keep autosave on a separate path from manual slots.
5. Round-trip GUT without relying on the real `user://` when possible (temp path).

## Patterns

### Capture / apply in sim

```gdscript
func capture_state() -> Dictionary:
	return {"version": 1, "seed": _seed, "scores": _scores.duplicate()}

func apply_state(data: Dictionary) -> void:
	# assume already migrated + validated by the IO layer
	_seed = int(data["seed"])
	_scores = data["scores"]
```

### Extend existing stores

Prefer extending `SettingsStore` / `ScoreStore` / `HighScoreTable` over a parallel
save framework. Reference: `engine/settings_store.gd`, `engine/score_store.gd`.

### Migration chain

```gdscript
func migrate(data: Dictionary) -> Dictionary:
	var v := int(data.get("version", 1))
	while v < CURRENT:
		data = _migrations[v].call(data)
		v += 1
		data["version"] = v
	return data
```

## Pitfalls

- `FileAccess` inside sim → forbidden; inject loaded data.
- In-place overwrite → corruption on crash; temp + rename.
- JSON numbers as float → `int()` version and large IDs.
- Serializing Node paths → scene renames break saves.

## Verify

```sh
godot --path . --headless -s addons/gut/gut_cmdln.gd \
  -gdir=res://tests/engine
```

Round-trip and vN→vN+1 migration tests.

## Docs to update

`docs/reference/engine-save.md`, game sim reference if capture_state is added.
