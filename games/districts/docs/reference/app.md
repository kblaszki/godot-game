---
title: Districts app
diataxis: reference
audience: [ai, human]
related_code:
  - games/districts/app/host.gd
  - games/districts/app/setup.gd
  - games/districts/app/play.gd
  - games/districts/app/pause_menu.gd
  - games/districts/app/district_tile_baker.gd
  - lab/launcher.gd
  - tests/games/districts/district_host_flow_test.gd
  - tests/games/districts/district_tile_baker_test.gd
related_docs:
  - ../index.md
  - sim.md
  - ../explanation/flow.md
  - ../../../../docs/reference/lab-shell.md
keywords: [districts, app, isometric, hotseat, tween, tile baker]
last_reviewed: 2026-11-05
---

# Districts app

| Scene | Role |
|-------|------|
| `setup` | Styled tablet card: 2–4 seats, bot toggles (seat 1 human), Start / Back |
| `play` | Wooden frame + felt, SubViewport board, tablet HUD (roster / feed / actions), dice overlay, space chip, win banner |
| `pause_menu` | Resume or return to setup |

Host stores `match_players`, `match_bot_mask`, `match_seed` for play. Esc opens pause. Game over → Enter returns to setup.

## Board tiles

`DistrictTileBaker` (`games/districts/app/district_tile_baker.gd`) bakes a **192×112** iso diamond `ImageTexture` per `BoardSpace` at board build:

- Property: group color band, name, `$price`, `rent $N`
- Tax / GO / Jail / Free / Goto Jail: distinct face colors, simple icons, title + money where relevant
- Headless-safe pure `Image` bake (bitmap labels; no GPU viewport)

Play spaces the ring at iso step **(86, 48)** and uses **linear** filtering on tile sprites. Each edge is rotated Monopoly-style (color band toward the center — tiles are not all aimed at the viewer). Ownership uses a colored **pip** on the tile. `SpaceChip` remains a compact summary above the board.

## Camera

Board lives in a `SubViewport`. **Fit board** tweens zoom, position, and rotation back to the full ring. **LMB drag** orbits (rotates) the view so edge labels can be read; **MMB drag** pans; mouse wheel zooms. During pawn hops the camera slowly follows position and eases rotation so the occupied edge reads upright; meeples counter-rotate to stay upright on screen.

## Juice

Play consumes sim events with Tweens: dice punch, per-step pawn hops + tile flash, buy pop + spark burst, cash toasts, camera shake on jail/bankrupt. Actions lock while `_busy`.

## Assets

`games/districts/assets/` — Kenney Boardgame Pack meeples/dice (CC0) + felt under `tiles/`. Space faces are procedural (baker). Legacy stripe PNGs under `tiles/` are unused fallbacks. See `assets/LICENSE.txt`.
