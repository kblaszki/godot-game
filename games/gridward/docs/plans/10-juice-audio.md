---
title: Gridward plan 10 — juice and audio
diataxis: how-to
audience: [ai, human]
related_code:
  - games/gridward/app/
  - art/gridward/
  - games/gridward/assets/pxl/
  - tests/games/gridward/
related_docs:
  - 09-hud-ux.md
  - 12-polish-ship.md
  - ../spec.md
  - ../../../../docs/how-to/make-pixel-art.md
keywords: [gridward, juice, audio, pxl]
last_reviewed: 2026-11-08
---

# 10 — Juice and audio

## Goal

Readable feedback without touching sim rules: projectiles/VFX, trauma shake on
leak, hit-stop by skipping host steps, SFX port, pxl tower icons. Success: GUT
still deterministic; icons load in HUD.

## Prerequisites

- [09-hud-ux.md](09-hud-ux.md)

## Scope

**In:** event→VFX/SFX mapping; camera trauma; pxl icons build; NullAudio in tests.  
**Out:** music layers, Steam builds.

## Files

| Path | Action |
|------|--------|
| `games/gridward/app/gridward_audio.gd` | add |
| `games/gridward/app/play.gd` / `board_3d.gd` | consume events |
| `art/gridward/icons.px.js` | add |
| `games/gridward/assets/pxl/` | build output `--no-preview` |
| `tests/games/gridward/` | audio null smoke if needed |

## Patterns

- Shake camera offset only (`game-feel`).
- Hit-stop: `_skip_sim_steps = N` on big kills.
- Build icons: `node tools/pxl/bin/pxl.js build art/gridward/icons.px.js --out games/gridward/assets/pxl --no-preview`

## GUT

- Determinism suite still passes with juice enabled (juice must not feed sim RNG).
- Optional: `test_icons_sheet_should_parse_with_pxl_sheet`

## Docs

`reference/app.md` feedback table; how-to link for pxl.

## Skills

`game-feel`, `game-audio`, `pixel-art-pxl`, `camera-systems`

## Verify

```sh
node tools/pxl/bin/pxl.js build art/gridward/icons.px.js --out games/gridward/assets/pxl --no-preview
godot --path . --headless --import
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/games/gridward
```

## Todos / commits

1. Events→VFX/SFX → `Add Gridward combat juice and audio port wiring.`
2. pxl icons → `Generate Gridward tower icons with pxl and wire HUD.`
