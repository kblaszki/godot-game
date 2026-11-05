---
title: Districts flow
diataxis: explanation
audience: [ai, human]
related_code:
  - games/districts/app/setup.gd
  - games/districts/app/play.gd
  - games/districts/sim/district_sim.gd
related_docs:
  - ../index.md
  - ../reference/app.md
  - ../reference/sim.md
keywords: [districts, flow]
last_reviewed: 2026-11-05
---

# Districts flow

```mermaid
stateDiagram-v2
  [*] --> setup
  setup --> play: StartMatch
  play --> pause: Esc
  pause --> play: Resume
  pause --> setup: QuitToSetup
  play --> setup: GameOverEnter
  setup --> labLauncher: Quit
```

Turn loop lives in `DistrictSim` (`roll` → resolve → optional `buy`/`skip` → next seat). Play queues those events through Tweens (dice → hops → offers) before unlocking input; bots call `bot_act` only when idle.
