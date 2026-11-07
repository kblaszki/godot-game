---
title: Fairway Circuit sim
diataxis: reference
audience: [ai, human]
related_code:
  - games/minigolf/sim/minigolf_config.gd
  - games/minigolf/sim/hole_def.gd
  - games/minigolf/sim/ball_state.gd
  - games/minigolf/sim/player_score.gd
  - games/minigolf/sim/course_catalog.gd
  - games/minigolf/sim/minigolf_sim.gd
  - games/minigolf/sim/minigolf_bot.gd
  - tests/games/minigolf/minigolf_physics_test.gd
related_docs:
  - ../index.md
  - app.md
  - ../explanation/flow.md
keywords: [minigolf, sim, MinigolfSim, physics]
last_reviewed: 2026-11-07
---

# Fairway Circuit sim

```mermaid
classDiagram
  class MinigolfConfig
  class HoleDef
  class BallState
  class PlayerScore
  class CourseCatalog
  class MinigolfSim {
    +setup(count, botMask, courseId, seed)
    +set_aim(dir)
    +set_power(t)
    +stroke()
    +tick(n)
    +resolve_stroke()
    +concede_hole()
    +advance_after_hole()
    +bot_act()
  }
  class MinigolfBot
  MinigolfSim --> MinigolfConfig
  MinigolfSim --> HoleDef
  MinigolfSim --> BallState
  MinigolfSim --> PlayerScore
  CourseCatalog --> HoleDef
  MinigolfBot --> MinigolfSim
```

Flat XZ proxy physics: semi-implicit Euler, kinetic friction, wall/blocker mirror bounce (`restitution` 0.55), cup sink when near and slow, OOB resets to last fairway. Course `fairway_park` has 9 holes from `CourseCatalog.build_fairway_park()`.

Phases: `aim` | `power` | `moving` | `hole_result` | `course_over`.

Hotseat is **per-hole**: every seat finishes the current hole before `advance_after_hole`.

## Events

| type | payload |
|------|---------|
| `aim_changed` | player, dir |
| `power_changed` | player, power |
| `stroke_started` | player, dir, power, impulse |
| `ball_moved` | pos, vel (throttled) |
| `bounced` | normal, speed |
| `stopped` | pos |
| `sunk` | player, strokes, par |
| `oob_reset` | pos |
| `hole_complete` | hole_index, scores_slice |
| `turn_changed` | player, hole |
| `course_complete` | winner, rankings |
