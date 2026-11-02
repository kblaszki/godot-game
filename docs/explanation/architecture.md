---
title: Architecture
diataxis: explanation
audience: [ai, human]
related_code: [engine/, lab/, games/, tests/, project.godot]
related_docs:
  - ../index.md
  - ../reference/source-layout.md
  - ../reference/engine-scene-stack.md
  - ../reference/lab-shell.md
  - ../how-to/write-headless-tests.md
  - ../how-to/add-a-game.md
keywords: [architecture, headless, sim, app, scene-flow, SceneRequest, SceneStack, lab, launcher]
last_reviewed: 2026-11-02
---

# Architecture

This lab keeps **rules** separate from **presentation**, and games nested under a **lab shell**.

- `engine/` — shared typed GDScript libraries (`RefCounted` / `class_name`). No `Node`.
- `lab/` — `LayeredHost`, lab host, launcher UI. `run/main_scene` points here.
- `games/<name>/sim/` — that game's deterministic rules (`RefCounted`). No scene tree.
- `games/<name>/app/` — game host + scenes that **consume** sim state and events.
- `tests/` — GUT suites that construct types headless.

```mermaid
flowchart TD
  LabHost[lab_host]
  Launcher[launcher]
  GameHost[game_host]
  Sim[sim RefCounted]
  LabHost --> Launcher
  LabHost -->|"REPLACE game host"| GameHost
  GameHost --> Sim
```

## Headless First

1. Implement the mechanic in `sim/` (or `engine/`).
2. Cover it with GUT under `tests/`.
3. Only then wire Nodes / `.tscn` in `app/`.

Sim code must not use `Node`, `get_tree()`, `Engine`, wall-clock `Time`, unseeded RNG, or `FileAccess`.

## Scene flow

[`SceneRequest`](../reference/engine-scene-stack.md) / [`SceneStack`](../reference/engine-scene-stack.md) live in `engine/`. [`LayeredHost`](../reference/lab-shell.md) applies `paths()` and keeps lower layers alive on `PUSH`.

Nested hosts: lab stack holds launcher or a game host; each game host has its own stack for menu / play / pause. Game Quit returns to the launcher via `return_to_launcher()`; only the lab Quit exits the process.

```mermaid
sequenceDiagram
  participant Child as menuOrPlay
  participant GameHost as gameHost
  participant LabHost as labHost
  Child->>GameHost: submit QUIT
  GameHost->>LabHost: return_to_launcher deferred
  LabHost->>LabHost: REPLACE launcher
```
