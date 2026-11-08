---
title: Gridward app
diataxis: reference
audience: [ai, human]
related_code:
  - games/gridward/app/host.gd
  - games/gridward/app/host.tscn
  - games/gridward/app/menu.gd
  - games/gridward/app/menu.tscn
  - games/gridward/app/play.gd
  - games/gridward/app/play.tscn
  - games/gridward/app/pause_menu.gd
  - games/gridward/app/pause_menu.tscn
  - games/gridward/app/board_3d.gd
  - games/gridward/app/board_3d.tscn
  - games/gridward/app/gridward_audio.gd
  - art/gridward/icons.px.js
  - games/gridward/assets/pxl/icons.json
  - lab/launcher.gd
  - tests/games/gridward/gridward_host_flow_test.gd
  - tests/games/gridward/gridward_play_test.gd
  - tests/games/gridward/gridward_board3d_test.gd
  - tests/games/gridward/gridward_juice_test.gd
related_docs:
  - ../index.md
  - ../explanation/flow.md
  - sim.md
  - ../../../../docs/reference/lab-shell.md
  - ../../../../docs/reference/engine-scene-stack.md
  - ../../../../docs/how-to/make-pixel-art.md
keywords: [gridward, app, host, menu, play, pause, HUD, build bar, LayeredHost, GridwardBoard3D, camera, cell pick, juice, audio, icons, trauma, hit-stop]
last_reviewed: 2026-11-09
---

# Gridward app

Presentation shell for Gridward. Entry is `games/gridward/app/host.tscn` (extends `lab/layered_host.gd`), registered in the lab launcher as **Gridward**. Scenes submit `SceneRequest`s. They do not own match rules.

```mermaid
classDiagram
  class Host {
    +submit()
    +sync_layers()
  }
  class Menu
  class Play
  class PauseMenu
  class SceneStack
  class GridwardSim
  class GridwardBoard3D
  class GridwardAudio
  class Camera3D
  Host --> SceneStack : owns
  Host --> Menu : boot replace
  Host --> Play : play replace
  Host --> PauseMenu : pause push
  Menu --> Host : submit
  Play --> Host : "push pause, pop via menu"
  PauseMenu --> Host : "pop or replace menu"
  Play --> GridwardSim : "step, commands"
  Play --> GridwardAudio : play_cue
  Play --> GridwardBoard3D : "sync and juice"
  GridwardBoard3D --> Camera3D : "orbit, pan, dolly, fit, trauma"
```

## Host

`_boot` `REPLACE`s `menu.tscn`. Window size stays lab-owned. `_on_quit_requested` walks parents for `return_to_launcher` and calls it deferred when nested; otherwise `get_tree().quit()`.

## Menu

| Button | Request |
|--------|---------|
| Play | `REPLACE` `play.tscn` |
| Quit | `QUIT` (returns to the lab launcher when nested) |

## Play

Play embeds `GridwardBoard3D` in a `SubViewport`, owns a Meadow `GridwardSim`, and steps it. Each frame calls `step()` once, or twice when speed is 2×, unless hit-stop is skipping steps. When pause is the top layer, `LayeredHost` disables play's process, so `step()` does not run. Events are drained after commands and after each step that ran. The board mirrors state and plays juice. It does not change rules.

| Corner / dock | Shows |
|---------------|--------|
| Top left `LivesGold` | Lives, gold |
| Top right `WaveCard` | Wave index, 1× / 2× button |
| Right `TowerPanel` | Selected tower: upgrade cost, sell, targeting |
| Bottom `BottomDock` | Next or current wave, build bar 1–5, Start Wave / Early Call, Menu |

The build bar lists `GridwardCatalog.TOWER_IDS` in order. Each button shows that tower's frame from `games/gridward/assets/pxl/icons.png`, parsed with `PxlSheet`, as an `AtlasTexture` with `TEXTURE_FILTER_NEAREST` and `expand_icon` off. The source is `art/gridward/icons.px.js` ([make pixel art](../../../../docs/how-to/make-pixel-art.md)). A type the map has not unlocked is disabled. Meadow starts with bolt selected. LMB on an empty buildable cell calls `place_tower` for the selected type. LMB on a tower selects it and opens the panel. RMB sells the tower under the cursor, or the selected tower when the cursor is on empty ground. Upgrade uses `GridwardSim.upgrade_cost` with default `GridwardConfig` factors, the same defaults the sim constructs. Sell calls `sell_tower`. The targeting list calls `set_targeting`.

Start Wave calls `start_wave`. During the post-clear intermission the button reads Early Call and the bonus from `early_call_bonus`. The preview line lists the current wave's counts. Victory and defeat replace that line and disable the button.

LMB drag orbits. MMB pans. The wheel dollies. The cursor ghost is green when `place_tower` would accept the selected type, and red otherwise.

## Input

Play registers these actions on the `InputMap` if they are missing, then samples them into `InputState` once per frame. Escape uses the built-in `ui_cancel` action.

| Action | Key | Command |
|--------|-----|---------|
| `gridward_tower_1` … `gridward_tower_5` | 1–5 (and keypad) | Select tower type |
| `gridward_start_wave` | Space | `start_wave` |
| `gridward_fit` | F | Fit camera |
| `gridward_speed` | Tab | Toggle 1× / 2× |
| `ui_cancel` | Esc | Push pause |

`_input` marks those events handled so Tab does not move focus and Space does not activate a focused button.

## Pause

`pause_menu.tscn` is a dimmed layer with Resume and Quit to menu. Resume grabs focus and pops. Quit to menu pops, then replaces play with the menu. Esc on the pause layer pops. The host does not tick the sim.

## Board

Script class is `GridwardBoard3D`. The scene node is `Board3D`. Districts already registers the global name `Board3D`.

One world unit is one cell. `cell_to_world` is the cell center on Y=0: cell `(x, y)` maps to `(x + 0.5, 0, y + 0.5)`. `world_to_cell` floors X and Z. Waypoints and enemies use the same half-cell offset through `point_to_world`. Path bars yaw with `yaw_for_xz_delta` (`atan2(-dz, dx)`), the same XZ convention as Fairway `Course3D`.

`cell_at_screen` casts the camera ray onto Y=0. A miss returns `MISS_CELL` (`Vector2i(2147483647, 2147483647)`), the integer stand-in for INF. `set_ghost` shows a green or red column, and hides it for `MISS_CELL`.

Cells, the path, towers, enemies, and in-flight shells are boxes, cylinders, and spheres parented to `BoardPivot3D`. Shells mirror `get_projectiles()`. The pivot stays put. Orbit, pan, dolly, and fit move `Camera3D` around the board center at about 40° pitch. Trauma adds a decaying offset to that camera pose only. `DisplayServer` headless (or the headless feature) skips every `MeshInstance3D`, including the ghost, shells, and juice meshes. Lights and the camera rig still exist.

## Feedback

`GridwardAudio.reaction` is a pure map from one event dictionary to a cue, volume, trauma, hit-stop count, and VFX id. Play applies it. The sim is not called back, and juice does not draw from the sim RNG.

Headless play and GUT use `NullAudio` (or an injected port such as `AudioSpy`). A windowed session builds `GodotAudio` blips inside `GridwardAudio`. There is no music bus.

Hit-stop sets `_skip_sim_steps` to 4. The host then withholds that many later `step()` calls. It does not change `Engine.time_scale` or the sim.

| Event | VFX | Cue | Trauma | Hit-stop |
|-------|-----|-----|--------|----------|
| `enemy_hit` | white flash mesh | `hit` | | |
| `enemy_killed` bounty under 50 | death pop (`TRANS_BACK`) | `kill` | | |
| `enemy_killed` boss, or bounty ≥ 50 | death pop | `kill_big` | 0.34 | 4 steps |
| `enemy_leaked` | | `leak` | 0.62 | |
| `tower_fired` hitscan or beam | tracer from tower to enemy | `fire` | | |
| `tower_fired` projectile | shell mesh from sim state | `fire` | | |
| `projectile_impact` | shockwave scaled by splash | `impact` | | |
| `tower_placed` | | `place` | | |
| `tower_sold` | | `sell` | | |
| `tower_upgraded` | | `upgrade` | | |
| `wave_started` | | `wave` | | |
| `wave_cleared` | | `clear` | | |
| `victory` | | `victory` | | |
| `defeat` | | `defeat` | 0.75 | |

```mermaid
sequenceDiagram
  participant Play
  participant Sim as GridwardSim
  participant Audio as GridwardAudio
  participant Board as GridwardBoard3D
  Play->>Sim: step
  Play->>Sim: drain_events
  Play->>Audio: play_cue
  Play->>Board: flash pop tracer trauma
  Note over Play: big kill sets _skip_sim_steps
```

```mermaid
sequenceDiagram
  participant Play
  participant Sim as GridwardSim
  participant Board as GridwardBoard3D
  Play->>Sim: get_towers and get_enemies
  Play->>Board: sync_from_sim
  Board->>Board: mirror grid path towers enemies
```
