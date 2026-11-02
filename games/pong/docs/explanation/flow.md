---
title: Pong scene flow
diataxis: explanation
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
  - engine/scene_stack.gd
  - engine/scene_request.gd
related_docs:
  - ../index.md
  - ../reference/app.md
  - ../reference/sim.md
  - ../../../../docs/explanation/architecture.md
  - ../../../../docs/reference/engine-scene-stack.md
keywords: [pong, flow, menu, play, pause, game-over, SceneStack]
last_reviewed: 2026-11-02
---

# Pong scene flow

The host is the only node that changes scenes. Menu, play, and pause enqueue a `SceneRequest` and return. The host applies the queue in `_process` (and once in `_ready` for the first menu).

`SceneStack` keeps path strings. The host calls `paths()` and syncs `Content` as **layers**: `PUSH` adds a child without freeing lower scenes; `POP` frees only the top child; `REPLACE` rebuilds from the mismatch point. Lower layers use `PROCESS_MODE_DISABLED` while an overlay is on top, so play stops stepping the sim during pause.

`QUIT` stays in the `apply` result and does not pop the stack. The pong host treats Quit as return-to-lab when nested under the lab shell; standalone it quits the tree.

Leaving pause for the main menu is a **batch**: `POP` then `REPLACE` menu (pause alone must not `REPLACE`, or play would remain under the menu).

Rally status stays inside `PongSim`. The play scene reads `get_status()`. When the sim reports `game_over`, Enter or Escape replaces play with the menu. During `playing` / `scored`, `pong_pause` pushes the pause overlay.

```mermaid
stateDiagram-v2
  [*] --> menu
  menu --> play: Start
  play --> pause: pong_pause
  pause --> play: Resume
  pause --> menu: QuitToMenu
  play --> gameOver: sim_game_over
  gameOver --> menu: EnterOrEscape
  menu --> labLauncher: Quit
```

```mermaid
sequenceDiagram
  participant Child as menuPlayOrPause
  participant Host as pongHost
  participant Stack as SceneStack
  Child->>Host: submit
  Host->>Stack: request
  Host->>Stack: apply
  Stack-->>Host: applied requests
  Host->>Host: sync_layers paths
```
