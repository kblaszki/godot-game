---
title: Districts flow
diataxis: explanation
audience: [ai, human]
related_code:
  - games/districts/app/setup.gd
  - games/districts/app/play.gd
  - games/districts/sim/district_sim.gd
  - games/districts/sim/match_session.gd
related_docs:
  - ../index.md
  - ../reference/app.md
  - ../reference/sim.md
keywords: [districts, flow, phases]
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

```mermaid
stateDiagram-v2
  [*] --> roll
  roll --> buy: unownedCity
  roll --> manage: resolved
  roll --> tour: tourSpace
  roll --> arena: arenaSpace
  roll --> chance: chanceSpace
  buy --> manage: bought
  buy --> auction: skipped
  auction --> manage: settled
  tour --> manage: teleported
  arena --> manage: resolved
  chance --> manage: drawn
  manage --> roll: endManageOrDoubles
  roll --> over: winner
  manage --> over: winner
```

Turn loop lives in `DistrictSim`. After movement resolution the seat often enters `manage` (build / gadgets / trade) before `end_manage` advances — doubles return to `roll`. Play queues sim events through Tweens before unlocking input; bots call `bot_act` only when idle. Online is stubbed via `MatchSession` + `LocalHotseatPort`.
