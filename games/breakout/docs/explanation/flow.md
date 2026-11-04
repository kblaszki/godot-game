---
title: Breakout scene flow
diataxis: explanation
audience: [ai, human]
related_code:
  - games/breakout/app/host.gd
  - games/breakout/app/main_menu.gd
  - games/breakout/app/play.gd
  - games/breakout/app/pause_menu.gd
related_docs:
  - ../index.md
  - ../reference/app.md
  - ../reference/sim.md
keywords: [breakout, flow, pause]
last_reviewed: 2026-11-04
---

# Breakout scene flow

```mermaid
stateDiagram-v2
  [*] --> menu
  menu --> play: Start
  play --> pause: breakout_pause
  pause --> play: Resume
  pause --> menu: QuitToMenu
  play --> cleared: allBricksGone
  play --> gameOver: livesZero
  cleared --> menu: EnterOrEscape
  gameOver --> menu: EnterOrEscape
  menu --> labLauncher: Quit
```
