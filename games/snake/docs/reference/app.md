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
  - project.godot
  - tests/games/snake/snake_host_flow_test.gd
related_docs:
  - ../index.md
  - ../explanation/flow.md
  - sim.md
  - ../../../../docs/reference/lab-shell.md
keywords: [snake, app, host, pause, InputMap]
last_reviewed: 2026-11-02
---

# Snake app

Entry: `games/snake/app/host.tscn` (extends `lab/layered_host.gd`). Nested under the lab shell; Quit returns via `return_to_launcher`.

| Scene | Role |
|-------|------|
| `main_menu` | Start → play; Quit → lab |
| `play` | Steps `SnakeSim`, draws grid with ColorRects |
| `pause_menu` | Resume `POP`; Quit to menu `POP`+`REPLACE` |

InputMap: `snake_up/down/left/right`, `snake_pause`.
