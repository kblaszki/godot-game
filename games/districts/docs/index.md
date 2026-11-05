---
title: Districts documentation
diataxis: reference
audience: [ai, human]
related_code:
  - games/districts/sim/
  - games/districts/app/
  - games/districts/assets/
  - tests/games/districts/
related_docs:
  - reference/sim.md
  - reference/app.md
  - explanation/flow.md
  - ../../../../docs/index.md
keywords: [districts, board, property, bots, hotseat, camera, index]
last_reviewed: 2026-11-05
---

# Districts

Original property-circuit board game (genre inspiration only — not Monopoly IP). Headless rules in `sim/`; 3D table in `app/` (`Board3D` in a SubViewport, corner HUD, procedural tiles from `DistrictTileBaker`, Kenney meeples/dice).

## Reference

| Doc | Purpose |
|-----|---------|
| [sim.md](reference/sim.md) | 32-space board, phases, chance, gadgets, auction, trade, net stubs |
| [app.md](reference/app.md) | Setup, 3D board, corner HUD |

## Explanation

| Doc | Purpose |
|-----|---------|
| [flow.md](explanation/flow.md) | Match and turn flow |

## Tests

- `district_sim_test.gd` — determinism, rent, buy, jail, bots
- `district_host_flow_test.gd` — setup/play/pause layers
