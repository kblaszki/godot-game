---
title: Fairway Circuit app
diataxis: reference
audience: [ai, human]
related_code:
  - games/minigolf/app/host.gd
  - games/minigolf/app/menu.gd
  - games/minigolf/app/setup.gd
  - games/minigolf/app/play.gd
  - games/minigolf/app/course_3d.gd
  - games/minigolf/app/pause_menu.gd
  - games/minigolf/app/results.gd
  - games/minigolf/app/minigolf_audio.gd
  - lab/launcher.gd
  - tests/games/minigolf/minigolf_host_flow_test.gd
related_docs:
  - ../index.md
  - sim.md
  - ../explanation/flow.md
keywords: [minigolf, app, Course3D, hud]
last_reviewed: 2026-11-07
---

# Fairway Circuit app

| Scene | Role |
|-------|------|
| `menu` | Play / Quit |
| `setup` | 1–4 seats, bot toggles (P1 human) |
| `play` | SubViewport `Course3D` + HUD |
| `pause_menu` | Resume / Quit to menu |
| `results` | Rankings from host meta |

```mermaid
flowchart TD
  playRoot[Play]
  sky[Sky]
  boardRoot[BoardRoot]
  svc[SubViewport]
  course[Course3D]
  pivot[BoardPivot3D]
  camera[Camera3D]
  topBar[TopBar]
  bottomBar[BottomBar]
  audio[MinigolfAudio]
  playRoot --> sky
  playRoot --> boardRoot
  boardRoot --> svc
  svc --> course
  course --> pivot
  course --> camera
  playRoot --> topBar
  playRoot --> bottomBar
  playRoot --> audio
```

## Course3D

Proxy-faithful meshes: fairway box, wall boxes (BoxMesh along +X, yaw `atan2(-dz, dx)` so segments match sim), bunker cylinders, cup+flag, muted tee disc. Hole 6 shows a tilted pad mesh over the damp region. Trees sit outside bounds. Camera pitch ~40°, LMB-drag orbit, click (no drag) aims via camera→Y=0 ray, MMB/RMB pan, wheel dolly, Fit biases focus toward the tee. During `moving`, focus leans toward the ball (`FOLLOW_LEAN`). Sun casts shadows.

Headless skips mesh creation (`DisplayServer` name `headless`).

## HUD / input

- Top: hole / par / stroke / player; Fit
- Aim: click fairway → ray to green; yellow shaft arrow from ball
- Power: hold Space, release → `stroke()`
- Tab scorecard; Esc pause; short feed tip
- Bots: `bot_act` on cooldown; ball ticks while `moving`
