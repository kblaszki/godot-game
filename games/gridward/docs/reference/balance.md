---
title: Gridward balance
diataxis: reference
audience: [ai, human]
related_code:
  - games/gridward/sim/gridward_config.gd
  - games/gridward/sim/gridward_sim.gd
  - games/gridward/sim/gridward_catalog.gd
  - tests/games/gridward/gridward_economy_test.gd
  - tests/games/gridward/gridward_lane_holds_test.gd
related_docs:
  - sim.md
  - ../index.md
  - ../spec.md
keywords: [gridward, economy, bounty, early-call, upgrade, lane-holds, Meadow]
last_reviewed: 2026-11-08
---

# Gridward balance

Numbers for Normal difficulty. Formulas match [spec.md](../spec.md) §7. The sim reads them from `GridwardConfig`. `difficulty_gold` is stored for later campaign setup and does not multiply these payouts.

## Payouts

| Event | Formula | Meadow note |
|-------|---------|-------------|
| Kill bounty | `EnemyDef.bounty` (not scaled by wave or HP) | grunt 8, runner 10 |
| Wave clear | `25 + 5 * wave_index` | wave 0 pays 25, wave 1 pays 30 |
| Early call | `min(40, floor(remaining_ticks / 30))` | only while the build timer remains |
| Sell refund | `floor(invested * 0.70)` | tier-0 bolt (50) refunds 35 |
| Starting gold | map field | Meadow 120 |
| Starting lives | map field | Meadow 20 |

`invested` is the build cost plus every upgrade paid. A leak does not change gold. The clear bonus is paid when the wave enters `WAVE_CLEAR`, including a wave that cleared by leaking. The last wave pays it before victory.

## Early call

The opening `BUILD` has no timer, so the first `start_wave` pays 0. Returning to `BUILD` after a clear starts `build_timer_ticks` (1500, 25 s). Each `step` in `BUILD` subtracts one tick. The timer does not start the wave.

`can_early_call` is true while that timer is above 0, lives are above 0, and a wave remains. `start_wave` adds `early_call_bonus` and clears the timer. A full timer would be `floor(1500 / 30) = 50`, which the cap clamps to 40. After 750 ticks the bonus is 25.

## Upgrade curve

Tier `t → t+1`: `round(base_cost * 0.75 * pow(1.55, t))`. Godot `roundi` rounds halves away from zero. Tiers stop at 2. Damage and range use `pow(1.35, tier)` and `pow(1.08, tier)` from the tier-0 base. Cooldown does not change.

| Tower | Base | t=0→1 | t=1→2 |
|-------|------|-------|-------|
| bolt | 50 | 38 | 58 |
| mortar | 80 | 60 | 93 |
| frost | 70 | 53 | 81 |
| flak | 90 | 68 | 105 |
| beam | 110 | 83 | 128 |

Bolt tier 1 is damage 16 and range 2.7. Bolt tier 2 is damage 22 and range 2.916.

## Wave HP

`max(1, round(base_hp * pow(1.12, wave_index) * difficulty_hp))`. `wave_index` is 0-based. Normal `difficulty_hp` is 1.

| Wave | Grunt HP | Runner HP |
|------|----------|-----------|
| 0 | 40 | 24 |
| 1 | 45 | 27 |
| 3 | 56 | 34 |
| 5 | 70 | 42 |
| 6 | 79 | 47 |
| 9 | 111 | 67 |

## Lane holds

Estimate for one enemy walking the whole path, summed over the reference towers:

`damage ≈ tower_dps * (path_coverage_length / enemy_speed)`

`tower_dps = damage / (cooldown_ticks * FixedTick.SEC)`. Bolt tier 0 is 12 damage every 30 ticks, 24 damage per second. Coverage is the polyline length inside the tower range (circle-segment overlap). Armor is not part of this estimate. Meadow mid waves use grunt and runner, both armor 0.

Require `damage >= scaled_hp * 1.15` for each enemy id on Meadow waves 3–6.

Reference loadout, both tier-0 bolts, both buildable, total cost 100 of Meadow's 120:

| Cell | Tower | Straight-lane coverage |
|------|-------|------------------------|
| (4, 0) | bolt | north lane, one cell off the path |
| (8, 0) | bolt | north lane, one cell off the path |

A bolt one cell beside a long straight covers `2 * sqrt(range^2 - 1)` cells. At range 2.5 that is about 4.58. Two of those chords are enough for the safety bar on waves 3–6.
