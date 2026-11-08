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
  - games/gridward/app/board_3d.gd
  - games/gridward/app/board_3d.tscn
  - lab/launcher.gd
  - tests/games/gridward/gridward_host_flow_test.gd
  - tests/games/gridward/gridward_board3d_test.gd
related_docs:
  - ../index.md
  - ../explanation/flow.md
  - sim.md
  - ../../../../docs/reference/lab-shell.md
  - ../../../../docs/reference/engine-scene-stack.md
keywords: [gridward, app, host, menu, play, LayeredHost, GridwardBoard3D, camera, cell pick]
last_reviewed: 2026-11-08
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
  class SceneStack
  class GridwardSim
  class GridwardBoard3D
  class Camera3D
  Host --> SceneStack : owns
  Host --> Menu : boot replace
  Host --> Play : play replace
  Menu --> Host : submit
  Play --> GridwardSim : reads
  Play --> GridwardBoard3D : sync_from_sim
  GridwardBoard3D --> Camera3D : "orbit, pan, dolly, fit"
```

## Host

`_boot` `REPLACE`s `menu.tscn`. Window size stays lab-owned. `_on_quit_requested` walks parents for `return_to_launcher` and calls it deferred when nested; otherwise `get_tree().quit()`.

## Menu

| Button | Request |
|--------|---------|
| Play | `REPLACE` `play.tscn` |
| Quit | `QUIT` (returns to the lab launcher when nested) |

## Play

Play embeds `GridwardBoard3D` in a `SubViewport` and mirrors a Meadow `GridwardSim`. A single label is the stub HUD. Lives, gold, the build bar, and wave controls are not in this scene.

The board reads towers and enemies each frame. It does not call `step()` and does not place towers. LMB drag orbits, RMB or MMB pans, the wheel dollies, and F fits the grid. The cursor ghost is green on an empty buildable cell and red otherwise.

## Board

Script class is `GridwardBoard3D`. The scene node is `Board3D`. Districts already registers the global name `Board3D`.

One world unit is one cell. `cell_to_world` is the cell center on Y=0: cell `(x, y)` maps to `(x + 0.5, 0, y + 0.5)`. `world_to_cell` floors X and Z. Waypoints and enemies use the same half-cell offset through `point_to_world`. Path bars yaw with `yaw_for_xz_delta` (`atan2(-dz, dx)`), the same XZ convention as Fairway `Course3D`.

`cell_at_screen` casts the camera ray onto Y=0. A miss returns `MISS_CELL` (`Vector2i(2147483647, 2147483647)`), the integer stand-in for INF. `set_ghost` shows a green or red column, and hides it for `MISS_CELL`.

Cells, the path, towers, and enemies are boxes and cylinders parented to `BoardPivot3D`. The pivot stays put. Orbit, pan, dolly, and fit move `Camera3D` around the board center at about 40° pitch. `DisplayServer` headless (or the headless feature) skips every `MeshInstance3D`, including the ghost. Lights and the camera rig still exist.

```mermaid
sequenceDiagram
  participant Play
  participant Sim as GridwardSim
  participant Board as GridwardBoard3D
  Play->>Sim: get_towers and get_enemies
  Play->>Board: sync_from_sim
  Board->>Board: mirror grid path towers enemies
```
