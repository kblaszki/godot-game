---
title: Documentation map
diataxis: reference
audience: [ai, human]
related_code: [project.godot, engine/, lab/, games/, tests/]
related_docs:
  - explanation/architecture.md
  - reference/source-layout.md
  - reference/lab-shell.md
  - reference/engine-input.md
  - reference/engine-save.md
  - reference/engine-audio.md
  - how-to/build-and-test.md
  - how-to/write-headless-tests.md
  - how-to/add-a-game.md
  - tutorials/create_new_game.md
keywords: [index, diataxis, map]
last_reviewed: 2026-11-02
---

# Documentation map

Cross-game and engine docs for the **godot-game** lab (Godot 4.x, typed GDScript).

## Explanation

| Doc | Purpose |
|-----|---------|
| [architecture.md](explanation/architecture.md) | Headless First, nested lab shell, scene-flow |

## How-to

| Doc | Purpose |
|-----|---------|
| [build-and-test.md](how-to/build-and-test.md) | Load project, run GUT, CI workflow |
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
| [lab-shell.md](reference/lab-shell.md) | Lab host, launcher, nested quit |
| [engine-scene-stack.md](reference/engine-scene-stack.md) | `SceneRequest` and `SceneStack` |
| [engine-core.md](reference/engine-core.md) | Fixed tick length and seeded RNG |
| [engine-input.md](reference/engine-input.md) | Headless `InputState` for action held/edges |
| [engine-save.md](reference/engine-save.md) | `HighScoreTable`, `ScoreStore`, `LabSettings`, `SettingsStore` |
| [engine-audio.md](reference/engine-audio.md) | `NullAudio` port and `GodotAudio` lab adapter |

## Game documentation

| Game | Docs |
|------|------|
| [pong](../games/pong/docs/index.md) | `PongSim` rally plus menu, play, pause; Quit returns to lab |
| [snake](../games/snake/docs/index.md) | `SnakeSim` grid snake plus menu, play, pause; Quit returns to lab |
