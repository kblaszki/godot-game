---
title: Pong documentation
diataxis: reference
audience: [ai, human]
related_code:
  - games/pong/sim/pong_config.gd
  - games/pong/sim/pong_sim.gd
  - games/pong/app/host.gd
  - games/pong/app/host.tscn
  - games/pong/app/main_menu.gd
  - games/pong/app/main_menu.tscn
  - games/pong/app/play.gd
  - games/pong/app/play.tscn
  - games/pong/app/pause_menu.gd
  - games/pong/app/pause_menu.tscn
  - tests/games/pong/pong_sim_test.gd
  - tests/games/pong/pong_host_flow_test.gd
related_docs:
  - reference/sim.md
  - reference/app.md
  - explanation/flow.md
  - ../../../../docs/index.md
  - ../../../../docs/explanation/architecture.md
keywords: [pong, sim, app, pause, index]
last_reviewed: 2026-11-02
---

# Pong

Rally rules live in `games/pong/sim/`. The window is `games/pong/app/`: a layered host drives `SceneStack`, the menu starts or quits, play steps `PongSim`, and pause overlays without destroying play.

## Reference

| Doc | Purpose |
|-----|---------|
| [sim.md](reference/sim.md) | `PongConfig`, `PongSim`, rally states, events |
| [app.md](reference/app.md) | Host, menu, play, pause, InputMap |

## Explanation

| Doc | Purpose |
|-----|---------|
| [flow.md](explanation/flow.md) | Menu, play, pause, and game-over scene flow |

## Tests

- `tests/games/pong/pong_sim_test.gd` — determinism, AI, scoring
- `tests/games/pong/pong_host_flow_test.gd` — layered host keep-alive across pause
