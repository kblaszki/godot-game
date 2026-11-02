---
title: Documentation map
diataxis: reference
audience: [ai, human]
related_code: [project.godot, engine/, games/, tests/]
related_docs:
  - explanation/architecture.md
  - reference/source-layout.md
  - how-to/build-and-test.md
  - how-to/write-headless-tests.md
  - how-to/add-a-game.md
  - tutorials/create_new_game.md
keywords: [index, diataxis, map]
last_reviewed: 2026-11-01
---

# Documentation map

Cross-game and engine docs for the **godot-game** lab (Godot 4.x, typed GDScript).

## Explanation

| Doc | Purpose |
|-----|---------|
| [architecture.md](explanation/architecture.md) | Headless First, sim vs app, scene-flow contract |

## How-to

| Doc | Purpose |
|-----|---------|
| [build-and-test.md](how-to/build-and-test.md) | Load project and run GUT |
| [write-headless-tests.md](how-to/write-headless-tests.md) | Sim/engine GUT conventions |
| [add-a-game.md](how-to/add-a-game.md) | Checklist to scaffold a new game |

## Tutorials

| Doc | Purpose |
|-----|---------|
| [create_new_game.md](tutorials/create_new_game.md) | End-to-end new game walkthrough |

## Reference

| Doc | Purpose |
|-----|---------|
| [source-layout.md](reference/source-layout.md) | Inventory of paths and suites |
| [engine-scene-stack.md](reference/engine-scene-stack.md) | `SceneRequest` and `SceneStack` |
| [engine-core.md](reference/engine-core.md) | Fixed tick length and seeded RNG |

## Game documentation

| Game | Docs |
|------|------|
| [pong](../games/pong/docs/index.md) | `PongSim` rally plus menu, play, pause overlay, and game-over |
