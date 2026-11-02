---
title: Lab shell
diataxis: reference
audience: [ai, human]
related_code:
  - lab/layered_host.gd
  - lab/layered_host.tscn
  - lab/lab_host.gd
  - lab/lab_host.tscn
  - lab/launcher.gd
  - lab/launcher.tscn
  - project.godot
  - tests/lab/lab_host_flow_test.gd
related_docs:
  - ../index.md
  - ../explanation/architecture.md
  - ../how-to/add-a-game.md
  - source-layout.md
  - engine-scene-stack.md
keywords: [lab, launcher, LayeredHost, nested-host]
last_reviewed: 2026-11-02
---

# Lab shell

`project.godot` `run/main_scene` is `res://lab/lab_host.tscn`. The lab owns a [`LayeredHost`](lab/layered_host.gd) stack. Games keep their own host under `games/<name>/app/host.tscn` and run nested inside the lab.

## LayeredHost

Shared base at `lab/layered_host.gd`: `SceneStack`, `submit`, `_flush`, `sync_layers`.

| Hook | Default | Override |
|------|---------|----------|
| `_boot()` | no-op | Enqueue the first scene |
| `_on_quit_requested()` | `get_tree().quit()` | Game hosts call lab `return_to_launcher` (deferred) |

## LabHost

| API | Behavior |
|-----|----------|
| `_boot` | Window 960×540, `REPLACE` launcher |
| `return_to_launcher()` | `REPLACE` launcher (drops nested game host) |
| Quit from launcher | `QUIT` → process exit |

## Launcher

`lab/launcher.gd` holds `GAMES` as `{title, host_path}` rows. Each row becomes a button that `REPLACE`s that game host. **Quit** submits `QUIT`.

## Nested quit

Pong menu Quit still submits `SceneRequest.quit()`. The pong host `_on_quit_requested` walks parents for `return_to_launcher` and calls it deferred. Standalone pong host (tests) falls back to `get_tree().quit()`.
