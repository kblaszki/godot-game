---
title: Gridward plan 12 — polish and ship
diataxis: how-to
audience: [ai, human]
related_code:
  - games/gridward/
  - tests/games/gridward/
related_docs:
  - 10-juice-audio.md
  - 11-campaign-save.md
  - 00-roadmap.md
  - ../spec.md
  - ../index.md
keywords: [gridward, polish, performance, ship]
last_reviewed: 2026-11-08
---

# 12 — Polish and ship

## Goal

Tutorial teach-then-test on Meadow, performance pooling, settings hooks, final
doc sweep, optional export. Success: acceptance checklist below all checked;
full GUT green.

## Prerequisites

- [10-juice-audio.md](10-juice-audio.md)
- [11-campaign-save.md](11-campaign-save.md)

## Scope

**In:** tutorial hints, MultiMesh/pool enemies, accessibility shake toggle if settings allow, Diátaxis final, ship-build optional.  
**Out:** Steam page copy, netcode.

## Files

| Path | Action |
|------|--------|
| `games/gridward/app/play.gd` | tutorial overlay |
| `games/gridward/app/board_3d.gd` | pool / MultiMesh |
| `games/gridward/docs/**` | final `last_reviewed`, fill stubs |
| `docs/reference/source-layout.md` | finalize code inventory |
| `export_presets.cfg` | optional via ship-build |

## Acceptance checklist

- [ ] Meadow → Citadel Normal completable by human
- [ ] Bot still clears Meadow
- [ ] Same-seed determinism green
- [ ] No FileAccess / Node in `sim/`
- [ ] Launcher entry **Gridward**
- [ ] `reference/sim.md`, `app.md`, `explanation/flow.md`, `balance.md` accurate
- [ ] Pixel icons nearest-filtered
- [ ] Pause / quit returns to lab
- [ ] Full `tests/games/gridward` GUT pass
- [ ] Spec non-goals still respected (no maze, no MP)

## GUT / verify

```sh
godot --path . --headless --import
godot --path . --headless --quit-after 1
godot --path . --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/games/gridward
godot --path . --headless -s addons/gut/gut_cmdln.gd
```

## Skills

`performance-optimization`, `game-feel`, `ship-build`, `update-docs`, `run-build-and-tests`

## Todos / commits

1. Tutorial + pooling → `Polish Gridward tutorial hints and enemy pooling.`
2. Doc sweep + acceptance → `Finalize Gridward docs and ship acceptance checklist.`

Optional separate: `Add Gridward export preset.` (only if templates available; no sudo).
