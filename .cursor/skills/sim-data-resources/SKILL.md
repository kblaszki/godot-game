---
name: sim-data-resources
description: >-
  Model game content as typed RefCounted or Resource defs consumed by the sim —
  HoleDef, CourseCatalog, configs — with loading injected by app/host. Use when
  adding data-driven levels, catalogs, card defs, or .tres content without
  FileAccess inside sim.
---

# Sim data resources

Owner: defs and catalogs under `games/<game>/sim/` (or shared `engine/` when
cross-game). Sim holds data; app/host loads files and injects instances.

Adapted from awesome-gamedev-agent-skills (`godot-resources`), Apache-2.0;
rewritten for godot-game Headless First.

## When to use / not

- Use for hole/course defs, board layouts, card data, dialogue graphs as data.
- Not for saving player progress → `save-systems`. Not for Node scenes as data.

## Workflow

1. Prefer `class_name X extends RefCounted` for pure data constructed in tests.
2. Use `Resource` / `.tres` when the editor pipeline helps; still inject into sim.
3. Catalog builders (`CourseCatalog.build_fairway_park()`) stay pure functions.
4. Never call `FileAccess` / `ResourceLoader` from sim code.
5. GUT constructs defs in code; optionally load `.tres` only in app tests.

## Patterns

### RefCounted def

```gdscript
class_name HoleDef
extends RefCounted

var id: String
var par: int
var tee: Vector2
var cup: Vector2
var walls: Array  # segment data
```

Reference: `games/minigolf/sim/hole_def.gd`, `course_catalog.gd`.

### Inject, don't load

```gdscript
# Host / app
var course := CourseCatalog.build_fairway_park()
var sim := MinigolfSim.new(config, course, seed)

# WRONG in sim:
# var res := load("res://...")
```

## Pitfalls

- `load()` inside sim → filesystem dependency, breaks Headless First.
- Giant autoload databases → prefer per-game catalogs.
- Untyped Dictionary soup → use typed fields; keep Dictionaries for serialization edges.

## Verify

Catalog size/ids stable; sim accepts injected defs; missing field fails loudly in test.

## Docs to update

`games/<game>/docs/reference/sim.md`, `docs/reference/source-layout.md` for new files.
