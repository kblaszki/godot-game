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
  - lab/settings.gd
  - lab/settings.tscn
  - lab/window_applier.gd
  - lab/godot_audio.gd
  - project.godot
  - tests/lab/lab_host_flow_test.gd
  - tests/lab/lab_settings_flow_test.gd
  - tests/lab/window_applier_test.gd
related_docs:
  - ../index.md
  - ../explanation/architecture.md
  - ../how-to/add-a-game.md
  - source-layout.md
  - engine-scene-stack.md
  - engine-save.md
  - engine-audio.md
keywords: [lab, launcher, settings, LayeredHost, nested-host, WindowApplier, GodotAudio, stretch]
last_reviewed: 2026-11-02
---

# Lab shell

`project.godot` `run/main_scene` is `res://lab/lab_host.tscn`. The lab owns a [`LayeredHost`](lab/layered_host.gd) stack. Games keep their own host under `games/<name>/app/host.tscn` and run nested inside the lab.

Display stretch is project-wide: viewport 1280×720, `canvas_items` + `keep`. Game hosts must not resize the window; the lab applies [`LabSettings`](engine-save.md) via `WindowApplier`.

## LayeredHost

Shared base at `lab/layered_host.gd`: `SceneStack`, `submit`, `_flush`, `sync_layers`.

| Hook | Default | Override |
|------|---------|----------|
| `_boot()` | no-op | Enqueue the first scene |
| `_on_quit_requested()` | `get_tree().quit()` | Game hosts call lab `return_to_launcher` (deferred) |

## LabHost

| API | Behavior |
|-----|----------|
| `_boot` | `SettingsStore.load` → `WindowApplier.apply`, then `REPLACE` launcher |
| `return_to_launcher()` | `REPLACE` launcher (drops nested game host) |
| Quit from launcher | `QUIT` → process exit |

## WindowApplier

`lab/window_applier.gd` maps `LabSettings` onto a `Window`:

| Mode | Effect |
|------|--------|
| `windowed` | `MODE_WINDOWED` + `window.size = resolution` |
| `fullscreen` | `MODE_FULLSCREEN` (stored resolution kept for return to windowed) |

## Launcher

`lab/launcher.gd` holds `GAMES` as `{title, host_path}` rows. Each row becomes a button that `REPLACE`s that game host. **Settings** `REPLACE`s `lab/settings.tscn`. **Quit** submits `QUIT`.

## Settings

`lab/settings.tscn` is lab-only (not in game pause menus). Controls:

| Control | Behavior |
|---------|----------|
| Resolution `<` / `>` | Cycle `LabSettings.RESOLUTIONS`; save + apply immediately |
| Mode | Toggle windowed / fullscreen; save + apply immediately |
| Back | `REPLACE` launcher |

Uses `SettingsStore.DEFAULT_PATH` (`user://settings.txt`) and `WindowApplier`.

## Nested quit

Pong menu Quit still submits `SceneRequest.quit()`. The pong host `_on_quit_requested` walks parents for `return_to_launcher` and calls it deferred. Standalone pong host (tests) falls back to `get_tree().quit()`.

## GodotAudio

`lab/godot_audio.gd` is the Node playback adapter for the duck-typed audio port (see [engine-audio](engine-audio.md)). Game hosts may own one instance and expose `get_audio()` for play scenes.
