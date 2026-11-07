---
title: Fairway Circuit documentation
diataxis: reference
audience: [ai, human]
related_code:
  - games/minigolf/sim/
  - games/minigolf/app/
  - games/minigolf/assets/
  - tests/games/minigolf/
related_docs:
  - reference/sim.md
  - reference/app.md
  - explanation/flow.md
  - ../../../../docs/index.md
keywords: [minigolf, fairway, putt, index]
last_reviewed: 2026-11-07
---

# Fairway Circuit

Kameralny putt-putt 3D (iso/orbit). Headless rules in `sim/`; presentation in `app/`.

## Reference

| Doc | Purpose |
|-----|---------|
| [sim.md](reference/sim.md) | Physics, holes, scoring, bot |
| [app.md](reference/app.md) | Course3D, HUD, scenes (when present) |

## Explanation

| Doc | Purpose |
|-----|---------|
| [flow.md](explanation/flow.md) | Match and stroke phases |

## Tests

- `minigolf_physics_test.gd` — bounce, friction, sink, OOB, determinism
- `minigolf_sim_test.gd` — scoring, hotseat, course complete
- `minigolf_bot_test.gd` — bot play / same-seed
- `minigolf_host_flow_test.gd` — scene layers
