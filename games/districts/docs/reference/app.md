---
title: Districts app
diataxis: reference
audience: [ai, human]
related_code:
  - games/districts/app/host.gd
  - games/districts/app/setup.gd
  - games/districts/app/play.gd
  - games/districts/app/pause_menu.gd
  - lab/launcher.gd
  - tests/games/districts/district_host_flow_test.gd
related_docs:
  - ../index.md
  - sim.md
  - ../explanation/flow.md
  - ../../../../docs/reference/lab-shell.md
keywords: [districts, app, isometric, hotseat]
last_reviewed: 2026-11-04
---

# Districts app

| Scene | Role |
|-------|------|
| `setup` | 2–4 seats, bot toggles (seat 1 human), Start / Back |
| `play` | Shared iso diamond ring, all pawns, roster, event log, Roll/Buy/Skip; bots auto via `bot_act` |
| `pause_menu` | Resume or return to setup |

Host stores `match_players`, `match_bot_mask`, `match_seed` for play. Esc opens pause. Game over → Enter returns to setup.
