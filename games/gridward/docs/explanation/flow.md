---
title: Gridward scene flow
diataxis: explanation
audience: [ai, human]
related_code:
  - games/gridward/app/host.gd
  - games/gridward/app/menu.gd
  - games/gridward/app/play.gd
  - games/gridward/sim/gridward_sim.gd
  - games/gridward/sim/enemy_state.gd
  - games/gridward/sim/gridward_events.gd
related_docs:
  - ../index.md
  - ../reference/app.md
  - ../reference/sim.md
  - ../reference/balance.md
  - ../spec.md
keywords: [gridward, flow, menu, play, build, wave, victory, defeat]
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

## Match phases

`GridwardSim` owns the match. `paused` is app-only: the host stops calling `step()`. The sim does not model pause.

```mermaid
stateDiagram-v2
  [*] --> build
  build --> wave: startWave
  wave --> waveClear: allSpawnedAndDead
  wave --> defeat: livesZero
  waveClear --> build: moreWaves
  waveClear --> victory: lastWave
  build --> defeat: livesZero
  victory --> [*]
  defeat --> [*]
```

`start_wave()` moves `build` to `wave`. Each `step()` during `wave` spawns entries that are due, moves enemies along the waypoint polyline, then advances projectiles and lets ready towers acquire and fire. A leak removes that enemy and loses one life. Lives at 0 set `defeat` in that same step, including when the leaking enemy was the last one alive.

When every entry has spawned and no enemies remain, that step enters `waveClear` and pays the wave-clear bonus. A kill pays that enemy's catalog bounty. The next `step()` leaves `waveClear`: `build` plus the intermission timer and the next wave index when waves remain, or `victory` on the last wave. `start_wave()` during the timer pays the early-call bonus from [balance.md](../reference/balance.md). `start_wave()` returns false outside `build`. The opening build has no timer.

```mermaid
sequenceDiagram
  participant Host
  participant Sim as GridwardSim
  Host->>Sim: start_wave()
  Host->>Sim: step()
  Sim->>Sim: spawnDue
  Sim->>Sim: moveEnemies
  Sim->>Sim: resolveCombat
  Sim->>Sim: checkLeakAndClear
  Host->>Sim: drain_events()
```
