---
title: Snake sim
diataxis: reference
audience: [ai, human]
related_code:
  - games/snake/sim/snake_config.gd
  - games/snake/sim/snake_sim.gd
  - tests/games/snake/snake_sim_test.gd
  - engine/fixed_tick.gd
  - engine/seeded_rng.gd
related_docs:
  - ../index.md
  - ../../../../docs/explanation/architecture.md
keywords: [snake, sim, grid, SeededRng]
last_reviewed: 2026-11-02
---

# Snake sim

Headless rules in `games/snake/sim/`.

## SnakeConfig

| Field | Default | Role |
|-------|---------|------|
| `width` / `height` | 20 / 15 | Grid size in cells |
| `cell` | 24 | Pixel cell size for presentation only |
| `move_every_ticks` | 6 | Move once per this many `step` calls |
| `start_length` | 3 | Initial segments including head |

## SnakeSim

| Method | Behavior |
|--------|----------|
| `set_input(dx, dy)` | Latches cardinal direction; applied on next move if not 180° reverse |
| `step(dt)` | Counts fixed ticks; on move: advance head, eat/grow, wall/self → `game_over` |
| Getters | `get_segments`, `get_food`, `get_score`, `get_status`, `get_direction` |

Events from `step`: `{type:"ate"}`, `{type:"game_over"}`. Food spawns on empty cells via `SeededRng`.
