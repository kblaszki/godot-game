---
title: Districts sim
diataxis: reference
audience: [ai, human]
related_code:
  - games/districts/sim/board_space.gd
  - games/districts/sim/player_state.gd
  - games/districts/sim/district_config.gd
  - games/districts/sim/district_sim.gd
  - games/districts/sim/district_bot.gd
  - tests/games/districts/district_sim_test.gd
related_docs:
  - ../index.md
  - app.md
  - ../explanation/flow.md
keywords: [districts, sim, DistrictSim, DistrictBot]
last_reviewed: 2026-11-04
---

# Districts sim

```mermaid
classDiagram
  class DistrictConfig
  class BoardSpace
  class PlayerState
  class DistrictSim {
    +setup(count, botMask, seed)
    +roll()
    +buy()
    +skip()
    +bot_act()
  }
  class DistrictBot {
    +should_buy(sim, id)$
  }
  DistrictSim --> DistrictConfig
  DistrictSim --> PlayerState
  DistrictSim --> BoardSpace
  DistrictBot --> DistrictSim
```

Default board: 28 spaces (GO, property groups, tax, jail, free, goto-jail). Phases: `roll`, `buy`, `over`.

| API | Behavior |
|-----|----------|
| `setup(n, bot_mask, seed)` | 2–4 players; bit `i` in mask ⇒ seat `i` is bot |
| `roll` / `buy` / `skip` | Human (or tests) drive the phase |
| `bot_act` | If current seat is bot: roll or buy/skip via `DistrictBot` |

v1: no trading, auctions, buildings, or chance deck. Doubles grant an extra roll; three doubles → jail. Bankruptcy clears ownership to creditor or bank.
