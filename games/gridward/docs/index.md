---
title: Gridward documentation
diataxis: reference
audience: [ai, human]
related_code:
  - games/gridward/
  - tests/games/gridward/
related_docs:
  - spec.md
  - reference/sim.md
  - reference/balance.md
  - reference/app.md
  - explanation/flow.md
  - plans/00-roadmap.md
  - ../../../docs/index.md
  - ../../../docs/explanation/architecture.md
keywords: [gridward, tower-defense, td, index, MapDef, catalog]
last_reviewed: 2026-11-08
---

# Gridward

Solo-campaign **fixed-path tower defense** in 3D. Status: **scaffold and data
model**. The lab launcher opens a layered host, menu, and play stub. `sim/`
holds `GridwardConfig`, entity defs, and `GridwardCatalog.build_meadow()`.

Presentation lives in `app/`. Follow
[architecture](../../../docs/explanation/architecture.md) and the plan series
under [plans/](plans/).

## Reference

| Doc | Purpose |
|-----|---------|
| [sim.md](reference/sim.md) | Config, defs, Meadow catalog, and match API |
| [balance.md](reference/balance.md) | Bounty, bonuses, upgrade curve, Meadow lane-holds |
| [app.md](reference/app.md) | Host, menu, play stub |

## Explanation

| Doc | Purpose |
|-----|---------|
| [flow.md](explanation/flow.md) | Menu, play, and stub build/wave phases |

## Spec

| Doc | Purpose |
|-----|---------|
| [spec.md](spec.md) | Full product and systems specification |

## Implementation plans

| Plan | Milestone |
|------|-----------|
| [00-roadmap](plans/00-roadmap.md) | Dependency graph, DoD, risks |
| [01-scaffold](plans/01-scaffold.md) | Game folders, host, launcher |
| [02-data-model](plans/02-data-model.md) | Defs, catalog, map 1 |
| [03-core-loop](plans/03-core-loop.md) | Waves, pathing, lives, gold |
| [04-towers](plans/04-towers.md) | Place, fire, targeting |
| [05-economy-balance](plans/05-economy-balance.md) | Curves, lane-holds |
| [06-enemy-roster](plans/06-enemy-roster.md) | Armor, air, statuses |
| [07-bot-harness](plans/07-bot-harness.md) | Utility bot clears map 1 |
| [08-board-3d](plans/08-board-3d.md) | Board3D, camera, pick |
| [09-hud-ux](plans/09-hud-ux.md) | Play HUD, pause |
| [10-juice-audio](plans/10-juice-audio.md) | Feel, SFX, pxl icons |
| [11-campaign-save](plans/11-campaign-save.md) | Maps, stars, progress |
| [12-polish-ship](plans/12-polish-ship.md) | Tutorial, perf, ship |

## Skills to compose

`sim-data-resources` · `sim-bot-ai` · `level-design` · `godot-3d-presentation` ·
`camera-systems` · `game-ui-ux` · `game-feel` · `game-audio` · `pixel-art-pxl` ·
`save-systems` · `genre-playbooks` (tower-defense) · `add-game`
