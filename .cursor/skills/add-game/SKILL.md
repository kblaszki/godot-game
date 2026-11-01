---
name: add-game
description: >-
  Creates a new game under games/<name>/ (headless sim, app scenes, GUT tests,
  and per-game Diataxis docs) on the shared Godot lab engine. Use when the user
  asks to add, scaffold, or start a new game or title.
---

# Add a game

Source of truth: [docs/tutorials/create_new_game.md](../../../docs/tutorials/create_new_game.md) and [docs/how-to/add-a-game.md](../../../docs/how-to/add-a-game.md). Model the layout on a sibling under `games/` when one exists, along with its `games/<game>/docs/`.

## Checklist

```
- [ ] games/<name>/{sim/, app/, docs/} created
- [ ] sim/ holds RefCounted rules only (no Node, no tree, seeded RNG, fixed tick)
- [ ] Sim GUT tests first under tests/games/<name>/ incl. same-seed determinism when random
- [ ] app/: scenes (.tscn) + Node scripts that consume sim state/events
- [ ] Scene flow follows docs/explanation/architecture.md (explicit requests; no invented SceneManager)
- [ ] games/<name>/docs/index.md + reference/sim.md + reference/app.md + explanation with Mermaid stateDiagram-v2
- [ ] Row in docs/index.md "Game documentation"; paths in docs/reference/source-layout.md
- [ ] Smoke-load project + GUT for tests/games/<name>/
```

## Rules

- Headless First (`headless-first.mdc`): rules are in the sim and tested before any drawing.
- Keep `class_name` / file names unique across the lab.
- Commit each verified step (golden rule), with explicit `git add` paths. Never commit `.godot/` cache junk or secrets.
