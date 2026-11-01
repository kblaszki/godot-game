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
  - tests/games/pong/pong_sim_test.gd
related_docs:
  - reference/sim.md
  - reference/app.md
  - explanation/flow.md
  - ../../../../docs/index.md
  - ../../../../docs/explanation/architecture.md
keywords: [pong, sim, app, index]
last_reviewed: 2026-11-01
---

# Pong

Rally rules live in `games/pong/sim/`. The window is `games/pong/app/`: a host drives `SceneStack`, the menu starts or quits, and play steps `PongSim`.

## Reference

| Doc | Purpose |
|-----|---------|
| [sim.md](reference/sim.md) | `PongConfig`, `PongSim`, rally states, events |
| [app.md](reference/app.md) | Host, main menu, and play scene |

## Explanation

| Doc | Purpose |
|-----|---------|
| [flow.md](explanation/flow.md) | Menu, play, and game-over scene flow |

## Tests

`tests/games/pong/pong_sim_test.gd` covers same-seed determinism, AI tracking, and scoring through `game_over`.
