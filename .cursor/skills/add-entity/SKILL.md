---
name: add-entity
description: >-
  Adds a new typed GDScript type under engine/ or games/<name>/, covers it with a
  headless GUT test, and documents it. Use when creating a library type in the
  shared engine, a game sim/app type, or a new game module class.
---

# Add a type to an engine or game module

Source of truth: [docs/reference/source-layout.md](../../../docs/reference/source-layout.md), [docs/explanation/architecture.md](../../../docs/explanation/architecture.md). For game types, also read `games/<name>/docs/index.md` when it exists.

## Checklist

```
- [ ] Decide the owner: headless engine/, <name>/sim (rules), or <name>/app (presentation)
- [ ] Create Name.gd under the owning folder (class_name Name, RefCounted for sim/engine)
- [ ] Add or extend a GUT suite under tests/engine/ or tests/games/<name>/
- [ ] Add or update the Diataxis reference entry (engine: docs/reference/; game: games/<name>/docs/reference/)
- [ ] Mermaid diagram if it changes architecture or a state flow
- [ ] Update docs/reference/source-layout.md for new files
```

## Steps

1. **Owner.** Follow Headless First (`headless-first.mdc`). Rules and mechanics belong in `games/<name>/sim/`. Shared features belong in `engine/`. Only presentation Nodes belong in `games/<name>/app/`.

2. **Script.** Typed GDScript, `class_name` PascalCase, one primary type:

```gdscript
class_name Name
extends RefCounted

func do_work() -> int:
	return 0
```

3. **Boundary.** Keep sim and headless engine code free of `Node`, `get_tree()`, `Engine`, wall-clock `Time`, unseeded RNG, and `FileAccess`.

4. **Test.** Write a headless GUT test under the matching `tests/` leaf. See [write-headless-tests.md](../../../docs/how-to/write-headless-tests.md).

5. **Docs.** Every new engine feature or game mechanic gets a Diátaxis entry in the same change. Refresh docs whose `related_code` lists the files you touched. Use the `update-docs` skill for a full sweep.
