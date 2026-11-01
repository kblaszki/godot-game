---
title: Add a game
diataxis: how-to
audience: [ai, human]
related_code: [games/, tests/games/, docs/]
related_docs:
  - ../index.md
  - ../tutorials/create_new_game.md
  - ../explanation/architecture.md
  - ../reference/source-layout.md
keywords: [add-game, scaffold, sim, app]
last_reviewed: 2026-11-01
---

# Add a game

Checklist (also encoded in the `add-game` skill):

1. Create `games/<name>/sim/`, `games/<name>/app/`, `games/<name>/docs/`.
2. Put rules in `sim/` as `RefCounted` (Headless First).
3. Add GUT suites under `tests/games/<name>/` **before** polishing scenes.
4. Add presentation under `app/` (`.tscn` + Node scripts) that consume sim output.
5. Write `games/<name>/docs/index.md`, `reference/sim.md`, `reference/app.md`, and an explanation with a Mermaid `stateDiagram-v2` for scene/game flow.
6. Add a row to the Game documentation table in [docs/index.md](../index.md).
7. Update [source-layout.md](../reference/source-layout.md).
8. Smoke-load the project and run GUT for `res://tests/games/<name>`.
