---
title: Gridward scene flow
diataxis: explanation
audience: [ai, human]
related_code:
  - games/gridward/app/host.gd
  - games/gridward/app/menu.gd
  - games/gridward/app/play.gd
related_docs:
  - ../index.md
  - ../reference/app.md
  - ../reference/sim.md
  - ../spec.md
keywords: [gridward, flow, menu, play, build, wave]
last_reviewed: 2026-11-08
---

# Gridward scene flow

The host boots to the menu. Play replaces that layer with a placeholder. Quit from the menu (or a later quit on the host) asks the lab to show the launcher again.

```mermaid
stateDiagram-v2
  [*] --> menu
  menu --> play: Play
  menu --> labLauncher: Quit
  play --> labLauncher: Quit
```

Sim phases below are names only. No wave loop runs in this scaffold.

```mermaid
stateDiagram-v2
  [*] --> build
  build --> wave: startWave
  wave --> build: moreWaves
```
