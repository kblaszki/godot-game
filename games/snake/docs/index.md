---
title: Snake documentation
diataxis: reference
audience: [ai, human]
related_code:
  - games/snake/sim/snake_config.gd
  - games/snake/sim/snake_sim.gd
  - tests/games/snake/snake_sim_test.gd
related_docs:
  - reference/sim.md
  - ../../../../docs/index.md
  - ../../../../docs/explanation/architecture.md
keywords: [snake, index]
last_reviewed: 2026-11-02
---

# Snake

Grid snake rules live in `games/snake/sim/`. Presentation lands in a later wave under `games/snake/app/`.

## Reference

| Doc | Purpose |
|-----|---------|
| [sim.md](reference/sim.md) | `SnakeConfig`, `SnakeSim` |

## Tests

`tests/games/snake/snake_sim_test.gd` — determinism, reverse ignore, eat/grow, collisions.
