---
title: Snake scene flow
diataxis: explanation
audience: [ai, human]
related_code:
  - games/snake/app/host.gd
  - games/snake/app/main_menu.gd
  - games/snake/app/play.gd
  - games/snake/app/pause_menu.gd
related_docs:
  - ../index.md
  - ../reference/app.md
  - ../reference/sim.md
keywords: [snake, flow, pause]
last_reviewed: 2026-11-02
---

# Snake scene flow

```mermaid
stateDiagram-v2
  [*] --> menu
  menu --> play: Start
  play --> pause: snake_pause
  pause --> play: Resume
  pause --> menu: QuitToMenu
  play --> gameOver: sim_game_over
  gameOver --> menu: EnterOrEscape
  menu --> labLauncher: Quit
```
