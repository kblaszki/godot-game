---
title: Gridward app
diataxis: reference
audience: [ai, human]
related_code:
  - games/gridward/app/host.gd
  - games/gridward/app/host.tscn
  - games/gridward/app/menu.gd
  - games/gridward/app/menu.tscn
  - games/gridward/app/play.gd
  - games/gridward/app/play.tscn
  - lab/launcher.gd
  - tests/games/gridward/gridward_host_flow_test.gd
related_docs:
  - ../index.md
  - ../explanation/flow.md
  - sim.md
  - ../../../../docs/reference/lab-shell.md
  - ../../../../docs/reference/engine-scene-stack.md
keywords: [gridward, app, host, menu, play, LayeredHost]
last_reviewed: 2026-11-08
---

# Gridward app

Presentation shell for Gridward. Entry is `games/gridward/app/host.tscn` (extends `lab/layered_host.gd`), registered in the lab launcher as **Gridward**. Scenes submit `SceneRequest`s. They do not own match rules.

```mermaid
classDiagram
  class Host {
    +submit()
    +sync_layers()
  }
  class Menu
  class Play
  class SceneStack
  Host --> SceneStack : owns
  Host --> Menu : boot replace
  Host --> Play : play replace
  Menu --> Host : submit
```

## Host

`_boot` `REPLACE`s `menu.tscn`. Window size stays lab-owned. `_on_quit_requested` walks parents for `return_to_launcher` and calls it deferred when nested; otherwise `get_tree().quit()`.

## Menu

| Button | Request |
|--------|---------|
| Play | `REPLACE` `play.tscn` |
| Quit | `QUIT` (returns to the lab launcher when nested) |

## Play

Placeholder scene. A label marks the stub. No sim, no board, no input rules.
