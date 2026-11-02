---
title: Snake app
diataxis: reference
audience: [ai, human]
related_code:
  - games/snake/app/host.gd
  - games/snake/app/host.tscn
  - games/snake/app/main_menu.gd
  - games/snake/app/main_menu.tscn
  - games/snake/app/play.gd
  - games/snake/app/play.tscn
  - games/snake/app/pause_menu.gd
  - games/snake/app/pause_menu.tscn
  - engine/input_state.gd
  - engine/high_score_table.gd
  - engine/score_store.gd
  - engine/null_audio.gd
  - lab/godot_audio.gd
  - project.godot
  - tests/games/snake/snake_host_flow_test.gd
related_docs:
  - ../index.md
  - ../explanation/flow.md
  - sim.md
  - ../../../../docs/reference/lab-shell.md
  - ../../../../docs/reference/engine-input.md
  - ../../../../docs/reference/engine-save.md
  - ../../../../docs/reference/engine-audio.md
keywords: [snake, app, host, pause, InputMap, InputState, high-score, audio]
last_reviewed: 2026-11-02
---

# Snake app

Entry: `games/snake/app/host.tscn` (extends `lab/layered_host.gd`). Nested under the lab shell; Quit returns via `return_to_launcher`. Host owns `GodotAudio` (`eat` / `die` blips) and exposes `get_audio()`.

| Scene | Role |
|-------|------|
| `main_menu` | Start → play; Quit → lab; shows `Best` from `user://scores/snake.txt` |
| `play` | Steps `SnakeSim`, draws grid; `ate`/`game_over` events play SFX; `game_over` inserts score once via `ScoreStore` |
| `pause_menu` | Resume `POP`; Quit to menu `POP`+`REPLACE` |

InputMap: `snake_up/down/left/right`, `snake_pause`. Play samples those movement actions into `InputState` each physics frame (priority left → right → up → down), then calls `set_input`. Pause and game-over use `_unhandled_input`.
