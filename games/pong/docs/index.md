---
title: Pong documentation
diataxis: reference
audience: [ai, human]
related_code:
  - games/pong/sim/pong_config.gd
  - games/pong/sim/pong_sim.gd
  - tests/games/pong/pong_sim_test.gd
related_docs:
  - reference/sim.md
  - ../../../../docs/index.md
  - ../../../../docs/explanation/architecture.md
keywords: [pong, sim, index]
last_reviewed: 2026-11-01
---

# Pong

Headless rally rules for Pong. Presentation is out of scope for this tree; `games/pong/sim/` owns the court, paddles, ball, score, and the right-paddle AI.

## Reference

| Doc | Purpose |
|-----|---------|
| [sim.md](reference/sim.md) | `PongConfig`, `PongSim`, rally states, events |

## Tests

`tests/games/pong/pong_sim_test.gd` covers same-seed determinism, AI tracking, and scoring through `game_over`.
