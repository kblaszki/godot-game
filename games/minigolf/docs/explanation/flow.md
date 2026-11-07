---
title: Fairway Circuit flow
diataxis: explanation
audience: [ai, human]
related_code:
  - games/minigolf/sim/minigolf_sim.gd
  - games/minigolf/app/menu.gd
  - games/minigolf/app/setup.gd
  - games/minigolf/app/play.gd
related_docs:
  - ../index.md
  - ../reference/sim.md
  - ../reference/app.md
keywords: [minigolf, flow, phases]
last_reviewed: 2026-11-07
---

# Fairway Circuit flow

```mermaid
stateDiagram-v2
  [*] --> menu
  menu --> setup: Play
  setup --> play: Start
  play --> pause: Esc
  pause --> play: Resume
  pause --> menu: Quit
  play --> results: CourseOver
  results --> menu: Again
```

```mermaid
stateDiagram-v2
  [*] --> aim
  aim --> power: setPower
  power --> moving: stroke
  aim --> moving: stroke
  moving --> aim: stoppedMiss
  moving --> holeResult: sunkAllPlayers
  holeResult --> aim: nextHole
  holeResult --> courseOver: lastHoleDone
```

Per-hole hotseat: when one seat sinks, the next unfinished seat tees off on the same hole. `hole_complete` fires only after every seat finishes; then `advance_after_hole`.
