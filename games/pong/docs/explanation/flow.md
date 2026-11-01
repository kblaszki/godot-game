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
  - engine/scene_stack.gd
  - engine/scene_request.gd
related_docs:
  - ../index.md
  - ../reference/app.md
  - ../reference/sim.md
  - ../../../../docs/explanation/architecture.md
  - ../../../../docs/reference/engine-scene-stack.md
keywords: [pong, flow, menu, play, game-over, SceneStack]
last_reviewed: 2026-11-01
---

# Pong scene flow

The host is the only node that changes scenes. Menu and play enqueue a `SceneRequest` and return. The host applies the queue in `_process` (and once in `_ready` for the first menu) so a button press is not freed mid-signal.

`SceneStack` keeps path strings. `QUIT` stays in the `apply` result and does not pop the stack. The host sees that kind and quits the tree.

Rally status stays inside `PongSim`. The play scene reads `get_status()`. It does not decide points or the winner. When the sim reports `game_over`, the scene shows the winner from the sim event and waits for Enter or Escape before replacing itself with the menu.

```mermaid
stateDiagram-v2
  [*] --> menu
  menu --> play: Start
  play --> gameOver: "sim status game_over"
  gameOver --> menu: "Enter or Escape"
  menu --> quitGame: Quit
```

```mermaid
sequenceDiagram
  participant Child as menuOrPlay
  participant Host as pongHost
  participant Stack as SceneStack
  Child->>Host: submit
  Host->>Stack: request
  Host->>Stack: apply
  Stack-->>Host: applied requests
  Host->>Host: swap Content or quit
```

Start replaces the menu with play. Quit asks the process to exit. After a winning point, play stays on screen until Enter or Escape replaces it with the menu. A new play scene builds a new `PongSim`.
