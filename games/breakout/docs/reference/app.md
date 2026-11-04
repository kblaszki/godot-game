---
title: Breakout app
diataxis: reference
audience: [ai, human]
related_code:
  - games/breakout/app/host.gd
  - games/breakout/app/host.tscn
  - games/breakout/app/main_menu.gd
  - games/breakout/app/main_menu.tscn
  - games/breakout/app/play.gd
  - games/breakout/app/play.tscn
  - games/breakout/app/pause_menu.gd
  - games/breakout/app/pause_menu.tscn
  - games/breakout/assets/
  - engine/view_fit.gd
  - engine/score_store.gd
  - lab/godot_audio.gd
  - project.godot
  - tests/games/breakout/breakout_host_flow_test.gd
related_docs:
  - ../index.md
  - ../explanation/flow.md
  - sim.md
  - ../../../../docs/reference/lab-shell.md
  - ../../../../docs/reference/engine-core.md
  - ../../../../docs/reference/engine-save.md
  - ../../../../docs/reference/engine-audio.md
keywords: [breakout, app, host, ViewFit, ScoreStore, assets]
last_reviewed: 2026-11-04
---

# Breakout app

Branded in UI as **Shatter**. Entry: `games/breakout/app/host.tscn` (extends `LayeredHost`). Nested under the lab; Quit returns via `return_to_launcher`. Host owns `GodotAudio` (`brick` / `die` / `clear`) and exposes `get_audio()`.

| Scene | Role |
|-------|------|
| `main_menu` | Neon title screen with drifting brick decor; Launch → play; Best from `user://scores/breakout.txt` |
| `play` | Starfield + horizon glow, ball trail, shatter bursts, screen shake, life orbs; `ViewFit`; score persist on clear/game over |
| `pause_menu` | Dim overlay + HOLD panel; Resume `POP`; Abort `POP`+`REPLACE` |

InputMap: `breakout_move_left/right`, `breakout_pause`. Lab launcher label: **Shatter**.

## Assets

`games/breakout/assets/` neon CC0 set (`paddle.png`, `ball.png`, `life.png`, `brick_0..4.png`). Optional swap: [GChoc Brick Breaker (CC0)](https://hollowsmilegames.itch.io/brick-breaker).
