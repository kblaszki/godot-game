---
title: Snake documentation
diataxis: reference
audience: [ai, human]
related_code:
  - games/snake/sim/snake_config.gd
  - games/snake/sim/snake_sim.gd
  - games/snake/app/host.gd
  - games/snake/app/play.gd
  - tests/games/snake/snake_sim_test.gd
  - tests/games/snake/snake_host_flow_test.gd
related_docs:
  - reference/sim.md
  - reference/app.md
  - explanation/flow.md
  - ../../../../docs/index.md
keywords: [snake, index]
last_reviewed: 2026-11-02
---

# Snake

Rules in `games/snake/sim/`. Presentation in `games/snake/app/` with layered host, pause, and lab Quit.

## Reference

| Doc | Purpose |
|-----|---------|
| [sim.md](reference/sim.md) | `SnakeConfig`, `SnakeSim` |
| [app.md](reference/app.md) | Host, menu, play, pause |

## Explanation

| Doc | Purpose |
|-----|---------|
| [flow.md](explanation/flow.md) | Scene flow including pause |

## Tests

- `snake_sim_test.gd` — determinism and rules
- `snake_host_flow_test.gd` — pause keep-alive
