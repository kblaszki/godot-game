---
title: Architecture
diataxis: explanation
audience: [ai, human]
related_code: [engine/, games/, tests/, project.godot]
related_docs:
  - ../index.md
  - ../reference/source-layout.md
  - ../reference/engine-scene-stack.md
  - ../how-to/write-headless-tests.md
  - ../how-to/add-a-game.md
keywords: [architecture, headless, sim, app, scene-flow, SceneRequest, SceneStack]
last_reviewed: 2026-11-01
---

# Architecture

This lab keeps **rules** separate from **presentation**.

- `engine/` — shared typed GDScript libraries (`RefCounted` / `class_name`). No `Node`.
- `games/<name>/sim/` — that game's deterministic rules (`RefCounted`). No scene tree.
- `games/<name>/app/` — Godot scenes (`.tscn`) and Node scripts that **consume** sim state and events.
- `tests/` — GUT suites that construct sim/engine types headless.

Godot itself is the runtime shell (window, rendering, input to Nodes). It is not where rules live.

```mermaid
flowchart LR
  subgraph shared [engine]
    CoreTypes[RefCounted libs]
  end
  subgraph game [games_name]
    Sim[sim RefCounted]
    App[app scenes]
  end
  Tests[GUT headless]
  Sim --> CoreTypes
  App --> Sim
  Tests --> Sim
  App --> GodotRuntime[Godot4 runtime]
```

## Headless First

1. Implement the mechanic in `sim/` (or `engine/`).
2. Cover it with GUT under `tests/`.
3. Only then wire Nodes / `.tscn` in `app/`.

Sim code must not use `Node`, `get_tree()`, `Engine`, wall-clock `Time`, unseeded RNG, or `FileAccess`. Time advances by a fixed tick; randomness is seeded.

## Scene flow

Presentation changes the active UI by enqueueing a [`SceneRequest`](../reference/engine-scene-stack.md) on a [`SceneStack`](../reference/engine-scene-stack.md), then calling `apply`. Both types live in `engine/` as `RefCounted` libraries. They store scene paths and request kinds. A host under `games/<name>/app/`, or a future lab launcher, reads `peek` and the list returned by `apply`, then performs the Godot scene change. Per-game flow stays documented under `games/<name>/docs/`.

`SceneRequest.Kind` is `PUSH`, `POP`, `REPLACE`, or `QUIT`. `scene_path` is set for `PUSH` and `REPLACE`. `QUIT` stays in the `apply` result so the host can quit; the path stack is left as it was.

```mermaid
classDiagram
  class SceneRequest {
    +Kind kind
    +String scene_path
  }
  class SceneStack {
    +request()
    +apply()
    +peek()
    +depth()
  }
  SceneStack --> SceneRequest : queues
```

```mermaid
sequenceDiagram
  participant Host as appHost
  participant Stack as SceneStack
  Host->>Stack: request
  Host->>Stack: apply
  Stack-->>Host: applied requests
  Host->>Host: change scene or quit
```

A thin lab launcher scene may eventually pick among games; until then `run/main_scene` in `project.godot` may be empty.
