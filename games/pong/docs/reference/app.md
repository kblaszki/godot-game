---
title: Pong app
diataxis: reference
audience: [ai, human]
related_code:
  - games/pong/app/host.gd
  - games/pong/app/host.tscn
  - games/pong/app/main_menu.gd
  - games/pong/app/main_menu.tscn
  - games/pong/app/play.gd
  - games/pong/app/play.tscn
  - games/pong/app/pause_menu.gd
  - games/pong/app/pause_menu.tscn
  - games/pong/sim/pong_config.gd
  - games/pong/sim/pong_sim.gd
  - engine/scene_stack.gd
  - engine/scene_request.gd
  - engine/fixed_tick.gd
  - engine/seeded_rng.gd
  - engine/input_state.gd
  - engine/view_fit.gd
  - project.godot
  - tests/games/pong/pong_host_flow_test.gd
related_docs:
  - ../index.md
  - ../explanation/flow.md
  - sim.md
  - ../../../../docs/explanation/architecture.md
  - ../../../../docs/reference/engine-scene-stack.md
  - ../../../../docs/reference/engine-input.md
  - ../../../../docs/reference/engine-core.md
  - ../../../../docs/reference/lab-shell.md
keywords: [pong, app, host, menu, play, pause, SceneStack, InputMap, InputState, ViewFit]
last_reviewed: 2026-11-02
---

# Pong app

Presentation for Pong lives in `games/pong/app/`. The game entry is `host.tscn` (extends `lab/layered_host.gd`), launched from the lab shell. Scenes draw with `ColorRect` and `Label` nodes. They do not embed rally rules.

```mermaid
classDiagram
  class Host {
    +submit()
    +sync_layers()
  }
  class MainMenu
  class Play
  class PauseMenu
  class SceneStack
  class PongSim
  Host --> SceneStack : owns
  Host --> MainMenu : layers
  Host --> Play : layers
  Host --> PauseMenu : overlay
  Play --> PongSim : owns
  MainMenu --> Host : submit
  Play --> Host : submit
  PauseMenu --> Host : submit
```

## Host

`host.tscn` extends `LayeredHost`. `_boot` `REPLACE`s the main menu. Window size/fullscreen belong to the lab shell (`WindowApplier`); the host does not resize the window. `_on_quit_requested` calls lab `return_to_launcher` (deferred) when nested; otherwise `get_tree().quit()` for standalone/tests.

## Main menu

| Button | Request |
|--------|---------|
| Start | `REPLACE` play |
| Quit | `QUIT` → returns to lab launcher when nested |

## Play

Builds `PongConfig`, `SeededRng(1)`, and `PongSim`. Steps on `FixedTick.SEC`. Each physics frame samples movement into an `InputState` (`pong_move_up` / `pong_move_down` → `get_axis`), then calls `set_input`. Pause and game-over still use `_unhandled_input`.

After layout, play calls `ViewFit.compute` with court size and the visible viewport, then sets `scale` / `position` so the court fills the lab viewport while sim coordinates stay unchanged.

| Action | Binding |
|--------|---------|
| `pong_move_up` | W, Up |
| `pong_move_down` | S, Down |
| `pong_pause` | Escape, P — `PUSH` pause (not in `game_over`) |
| `ui_accept` / `ui_cancel` | After `game_over` — `REPLACE` menu |

## Pause

Semi-transparent overlay over live play.

| Control | Request |
|---------|---------|
| Resume / `pong_pause` / `ui_cancel` | `POP` |
| Quit to menu | `POP` then `REPLACE` menu (one flush batch) |

## Run

```sh
godot --path .
```
