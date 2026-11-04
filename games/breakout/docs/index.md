---
title: Breakout documentation
diataxis: reference
audience: [ai, human]
related_code:
  - games/breakout/sim/breakout_config.gd
  - games/breakout/sim/breakout_sim.gd
  - games/breakout/app/host.gd
  - games/breakout/app/play.gd
  - games/breakout/assets/
  - tests/games/breakout/breakout_sim_test.gd
  - tests/games/breakout/breakout_host_flow_test.gd
related_docs:
  - reference/sim.md
  - reference/app.md
  - explanation/flow.md
  - ../../../../docs/index.md
keywords: [breakout, brick-breaker, index]
last_reviewed: 2026-11-04
---

# Breakout

Brick-breaker rules in `games/breakout/sim/`. Presentation in `games/breakout/app/` with layered host, pause, high scores, and lab Quit.

Pixel placeholders under `games/breakout/assets/` (CC0). Recommended drop-in art: [Brick Breaker Pixel Art by GChoc (CC0)](https://hollowsmilegames.itch.io/brick-breaker).

## Reference

| Doc | Purpose |
|-----|---------|
| [sim.md](reference/sim.md) | `BreakoutConfig`, `BreakoutSim` |
| [app.md](reference/app.md) | Host, menu, play, pause, assets |

## Explanation

| Doc | Purpose |
|-----|---------|
| [flow.md](explanation/flow.md) | Scene flow including pause and clear |

## Tests

- `breakout_sim_test.gd` — determinism, bricks, lives
- `breakout_host_flow_test.gd` — pause keep-alive
