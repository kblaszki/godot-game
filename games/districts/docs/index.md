---
title: Districts documentation
diataxis: reference
audience: [ai, human]
related_code:
  - games/districts/sim/
  - games/districts/app/
  - tests/games/districts/
related_docs:
  - reference/sim.md
  - reference/app.md
  - explanation/flow.md
  - ../../../../docs/index.md
keywords: [districts, board, property, bots, hotseat, index]
last_reviewed: 2026-11-04
---

# Districts

Original property-circuit board game (genre inspiration only — not Monopoly IP). Headless rules in `sim/`; shared isometric 2.5D table in `app/`. Local hotseat 2–4 seats with optional bots.

## Reference

| Doc | Purpose |
|-----|---------|
| [sim.md](reference/sim.md) | Board, turns, bots |
| [app.md](reference/app.md) | Setup, play HUD, iso board |

## Explanation

| Doc | Purpose |
|-----|---------|
| [flow.md](explanation/flow.md) | Match and turn flow |

## Tests

- `district_sim_test.gd` — determinism, rent, buy, jail, bots
- `district_host_flow_test.gd` — setup/play/pause layers
