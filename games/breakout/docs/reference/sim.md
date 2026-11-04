---
title: Breakout sim
diataxis: reference
audience: [ai, human]
related_code:
  - games/breakout/sim/breakout_config.gd
  - games/breakout/sim/breakout_sim.gd
  - tests/games/breakout/breakout_sim_test.gd
related_docs:
  - ../index.md
  - ../explanation/flow.md
  - app.md
  - ../../../../docs/reference/engine-core.md
keywords: [breakout, sim, BreakoutConfig, BreakoutSim]
last_reviewed: 2026-11-04
---

# Breakout sim

Headless brick-breaker rules. No `Node`, filesystem, or wall-clock.

```mermaid
classDiagram
  class BreakoutConfig {
    +court_width
    +court_height
    +brick_rows
    +brick_cols
    +start_lives
  }
  class BreakoutSim {
    +set_input(dir)
    +step(dt)
    +get_score()
    +get_lives()
    +get_status()
  }
  BreakoutSim --> BreakoutConfig
  BreakoutSim --> SeededRng
```

## BreakoutConfig

Defaults: court `800×450`, paddle `80×12`, ball radius `6`, speed `320`, bricks `5×10`, `start_lives` `3`, `points_per_brick` `10`.

## BreakoutSim

| API | Behavior |
|-----|----------|
| `set_input(dir)` | `-1` / `0` / `1` horizontal paddle |
| `step(dt)` | Move paddle/ball; walls L/R/T; paddle angle bounce; brick AABB; bottom = life |
| Status | `playing`, `life_lost` (hold then serve), `game_over`, `cleared` |

Events: `brick_broken`, `life_lost`, `game_over`, `cleared`. Same seed + inputs → same trajectory (GUT).
