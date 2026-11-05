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

`DistrictTileBaker` bakes **rectangular** Monopoly faces (edge **80×112**, corners **112×112**):

- Property / tax: color band on the **outer** edge, cream face, name + money
- Corners (GO / Jail / Free / Goto Jail): square tiles with icons + title
- Headless-safe pure `Image` bake (bitmap labels)

Play lays a **square track** (corners + abutting edge rectangles), rotates `BoardPivot` by −45° for the diamond table view, and orients each side so the band faces outward (labels read from that side of the table). Felt + center plate live under the ring. Ownership uses a colored **pip**.

## Camera

Board lives in a `SubViewport` with `transparent_bg` (UI felt/frame show through). **`BoardPivot`** holds table + tiles + pawns. **LMB drag** orbits the table around its center; **MMB** pans the camera; wheel zooms. **Fit board** eases zoom/camera to the ring and resets pivot rotation (~0.5s). During hops the camera slowly follows the active tile while the pivot eases so that edge sits upright.

## Juice

Play consumes sim events with Tweens: dice punch, per-step pawn hops + tile flash, buy pop + spark burst, cash toasts, camera shake on jail/bankrupt. Actions lock while `_busy`.

## Assets

`games/districts/assets/` — Kenney Boardgame Pack meeples/dice (CC0) + felt under `tiles/`. Space faces are procedural (baker). Legacy stripe PNGs under `tiles/` are unused fallbacks. See `assets/LICENSE.txt`.
