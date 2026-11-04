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

Entry: `games/breakout/app/host.tscn` (extends `LayeredHost`). Nested under the lab; Quit returns via `return_to_launcher`. Host owns `GodotAudio` (`brick` / `die` / `clear`) and exposes `get_audio()`.

| Scene | Role |
|-------|------|
| `main_menu` | Start → play; Quit → lab; Best from `user://scores/breakout.txt` |
| `play` | Steps `BreakoutSim`, draws sprites from `assets/`, `ViewFit` scales court; persists score on clear/game over |
| `pause_menu` | Resume `POP`; Quit to menu `POP`+`REPLACE` |

InputMap: `breakout_move_left/right`, `breakout_pause`.

## Assets

`games/breakout/assets/` holds lab CC0 pixel placeholders (`paddle.png`, `ball.png`, `brick_0..4.png`). Swap with [GChoc Brick Breaker (CC0)](https://hollowsmilegames.itch.io/brick-breaker) if desired; keep the same filenames or update preloads in `play.gd`.
