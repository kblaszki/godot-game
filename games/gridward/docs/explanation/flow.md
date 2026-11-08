---
title: Gridward scene flow
diataxis: explanation
audience: [ai, human]
related_code:
  - games/gridward/app/host.gd
  - games/gridward/app/menu.gd
  - games/gridward/app/map_select.gd
  - games/gridward/app/play.gd
  - games/gridward/app/pause_menu.gd
  - games/gridward/app/results.gd
  - games/gridward/app/progress_store.gd
  - games/gridward/sim/gridward_progress.gd
  - games/gridward/sim/gridward_sim.gd
  - games/gridward/sim/enemy_state.gd
  - games/gridward/sim/gridward_events.gd
related_docs:
  - ../index.md
  - ../reference/app.md
  - ../reference/sim.md
  - ../reference/balance.md
  - ../spec.md
keywords: [gridward, flow, menu, map select, play, pause, results, stars, save, build, wave, victory, defeat, speed]
last_reviewed: 2026-11-09
---

# Gridward scene flow

The host loads `GridwardProgress` and boots to the menu. Play opens map select. Start replaces that layer with the match for the chosen map and difficulty. Esc pushes pause on top of play. Resume pops back to play. Quit to menu pops pause and replaces play with the menu. Victory or defeat records the result and replaces play with results. Results can return to map select or the menu. Quit from the menu asks the lab to show the launcher again.

```mermaid
stateDiagram-v2
  [*] --> menu
  menu --> mapSelect: Play
  menu --> labLauncher: Quit
  mapSelect --> menu: Back
  mapSelect --> play: Start
  play --> pause: Esc
  pause --> play: Resume
  pause --> menu: QuitToMenu
  play --> results: victoryOrDefeat
  results --> mapSelect: MapSelect
  results --> menu: Menu
```

A win writes the best star count for that map and difficulty, then the host saves. A loss leaves the file alone. Stars use lives left at victory: 15 or more is 3, 8 or more is 2, any other win is 1. Meadow starts unlocked. Each later map needs one star on the map before it.

```mermaid
sequenceDiagram
  participant Play
  participant Host
  participant Progress as GridwardProgress
  participant Store as GridwardProgressStore
  Play->>Host: note_result
  Note over Host: victory keeps best stars
  Host->>Progress: record_victory
  Host->>Store: save
  Play->>Host: replace results
```

While pause is the top layer, `LayeredHost` sets play to `PROCESS_MODE_DISABLED`. Play's `_process` is what calls `step()`, so the match holds. The sim has no paused phase.

```mermaid
sequenceDiagram
  participant Play
  participant Host
  participant Sim as GridwardSim
  participant Board as GridwardBoard3D
  Play->>Host: push pause
  Note over Host: play process stops
  Host->>Play: pop resume
  loop step slots
    Play->>Sim: step unless hit-stop
    Play->>Sim: drain_events
  end
  Play->>Board: juice and sync
```

## Match phases

`GridwardSim` owns the match. Pause is app-only.

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
  participant Play
  participant Sim as GridwardSim
  Play->>Sim: start_wave()
  Play->>Sim: step()
  Sim->>Sim: spawnDue
  Sim->>Sim: moveEnemies
  Sim->>Sim: resolveCombat
  Sim->>Sim: checkLeakAndClear
  Play->>Sim: drain_events()
```

At 1×, play calls `step()` once per frame. At 2× it calls `step()` twice. A big kill sets `_skip_sim_steps`, and each following step slot is skipped until that count hits zero. Play drains events after every step that ran. Those events drive juice only. They do not call back into the sim.
