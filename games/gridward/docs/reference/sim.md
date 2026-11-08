---
title: Gridward sim
diataxis: reference
audience: [ai, human]
related_code:
  - games/gridward/sim/gridward_config.gd
  - games/gridward/sim/map_def.gd
  - games/gridward/sim/enemy_def.gd
  - games/gridward/sim/tower_def.gd
  - games/gridward/sim/wave_def.gd
  - games/gridward/sim/gridward_catalog.gd
  - games/gridward/sim/gridward_progress.gd
  - games/gridward/sim/enemy_state.gd
  - games/gridward/sim/status_effect.gd
  - games/gridward/sim/tower_state.gd
  - games/gridward/sim/projectile_state.gd
  - games/gridward/sim/gridward_sim.gd
  - games/gridward/sim/gridward_bot.gd
  - games/gridward/sim/gridward_events.gd
  - tests/games/gridward/gridward_catalog_test.gd
  - tests/games/gridward/gridward_sim_test.gd
  - tests/games/gridward/gridward_towers_test.gd
  - tests/games/gridward/gridward_economy_test.gd
  - tests/games/gridward/gridward_lane_holds_test.gd
  - tests/games/gridward/gridward_roster_test.gd
  - tests/games/gridward/gridward_bot_test.gd
  - tests/games/gridward/gridward_progress_test.gd
  - tests/games/gridward/gridward_campaign_test.gd
related_docs:
  - ../index.md
  - ../spec.md
  - balance.md
  - ../explanation/flow.md
  - ../../../../docs/explanation/architecture.md
keywords: [gridward, sim, MapDef, GridwardCatalog, GridwardProgress, GridwardSim, GridwardBot, WaveDef, Meadow, Bend, Skyreach, Bastion, Citadel, stars, difficulty, leak, towers, targeting, economy, early-call, armor, status, beam, slow, bot]
last_reviewed: 2026-11-09
---

# Gridward sim

Headless content and match loop. `GridwardCatalog` builds defs in code. `GridwardSim` steps the match from those defs. Scripts under `games/gridward/sim/` are `RefCounted` and stay free of `Node`, the scene tree, wall-clock `Time`, unseeded RNG, and `FileAccess`.

Product numbers are copied from [spec.md](../spec.md) §§5–9. Phase transitions are drawn in [flow.md](../explanation/flow.md).

## Ownership

```mermaid
classDiagram
  class GridwardSim {
    +start_wave()
    +can_early_call()
    +early_call_bonus()
    +step()
    +place_tower(cell, towerId)
    +sell_tower(id)
    +upgrade_tower(id)
    +set_targeting(id, mode)
    +drain_events()
    +get_phase()
    +get_gold()
    +get_lives()
    +get_wave_index()
    +get_enemies()
    +get_towers()
    +get_projectiles()
  }
  class GridwardCatalog {
    +build_map(id)
    +build_meadow()
    +build_bend()
    +build_skyreach()
    +build_bastion()
    +build_citadel()
    +enemy(id)
    +tower(id)
  }
  class GridwardProgress {
    +stars_for(mapId, difficulty)
    +is_unlocked(mapId)
    +record_victory(mapId, difficulty, lives)
    +capture_state()
    +apply_state(data)
  }
  class MapDef {
    +waypoints
    +buildable
    +waves
    +path_cells()
    +apply_buildable_off_path()
  }
  class WaveDef {
    +entries
  }
  class EnemyDef
  class TowerDef
  class GridwardConfig
  class EnemyState
  class StatusEffect
  class TowerState
  class ProjectileState
  class GridwardEvents
  class GridwardBot {
    +act()
  }
  class SeededRng
  GridwardBot --> GridwardSim
  GridwardBot --> GridwardCatalog
  GridwardSim --> MapDef
  GridwardSim --> GridwardCatalog
  GridwardSim --> GridwardConfig
  GridwardSim --> EnemyState
  GridwardSim --> StatusEffect
  EnemyState --> StatusEffect
  GridwardSim --> TowerState
  GridwardSim --> ProjectileState
  GridwardSim --> GridwardEvents
  GridwardSim --> SeededRng
  GridwardCatalog --> MapDef
  GridwardCatalog --> EnemyDef
  GridwardCatalog --> TowerDef
  GridwardProgress --> GridwardCatalog
  GridwardProgress --> GridwardConfig
  MapDef --> WaveDef
```

`enemy(id)` and `tower(id)` return a new def on each call. An unknown id returns `null`. `GridwardConfig` is a separate tunable bag (Normal defaults). The catalog does not load files. The sim constructs its own `GridwardConfig` and a `SeededRng` from the constructor seed. `GridwardBot` is not owned by the sim. It calls the public match API.

## GridwardSim

```gdscript
enum Phase { BUILD, WAVE, WAVE_CLEAR, VICTORY, DEFEAT }
func _init(map: MapDef, catalog: GridwardCatalog, seed: int) -> void
func get_phase() -> int
func get_gold() -> int
func get_lives() -> int
func get_wave_index() -> int
func can_early_call() -> bool
func early_call_bonus() -> int
func start_wave() -> bool
func step() -> void
func drain_events() -> Array
func get_enemies() -> Array
func get_towers() -> Array
func get_projectiles() -> Array
func place_tower(cell: Vector2i, tower_id: StringName) -> int
func sell_tower(tower_entity_id: int) -> bool
func upgrade_tower(tower_entity_id: int) -> bool
func set_targeting(tower_entity_id: int, mode: StringName) -> void
```

| Method | Behavior |
|--------|----------|
| `_init` | Copies `starting_gold` and `starting_lives`. Phase is `BUILD`, or `DEFEAT` when lives start at 0 or below. Owns `SeededRng(seed)` and a default `GridwardConfig`. |
| `get_phase` | `Phase` value as an int. |
| `get_gold` | Current gold. Kills, wave clears, and early calls add to it. A leak leaves it unchanged. |
| `get_lives` | Lives remaining after leaks. |
| `get_wave_index` | Active wave during `WAVE` and `WAVE_CLEAR`. Next wave during `BUILD` after a clear. `0` before the first wave. Stays on the last index at `VICTORY`. |
| `can_early_call` | True in `BUILD` when the post-clear timer remains, lives are above 0, and a wave remains. False during the opening build. |
| `early_call_bonus` | Gold `start_wave` will add. `min(cap, floor(remaining / ticks_per_gold))`, or 0 when `can_early_call` is false. |
| `start_wave` | From `BUILD` only, when lives are above 0 and a wave remains. Adds `early_call_bonus`, clears the timer, enters `WAVE`, schedules that wave, emits `wave_started`. Returns false otherwise. |
| `step` | One `FixedTick.SEC` of the wave, or the exit from `WAVE_CLEAR`. In `BUILD`, decrements a pending intermission timer by one. No-op in `VICTORY`, `DEFEAT`, and in `BUILD` when the timer is already 0. |
| `drain_events` | Returns queued event dictionaries and clears the queue. |
| `get_enemies` | Shallow copy of living `EnemyState`s in spawn order. |
| `get_towers` | Shallow copy of placed `TowerState`s in place order. |
| `get_projectiles` | Shallow copy of shells still in flight. |
| `place_tower` | Entity id, or `-1`. See [Placement](#placement). |
| `sell_tower` | Refunds `floor(invested * sell_refund)` and removes the tower. False when the phase is closed or the id is missing. |
| `upgrade_tower` | Pays the next-tier cost, then scales damage and range. False at `max_tier`, when gold is short, or when the phase is closed. |
| `set_targeting` | Sets `first`, `last`, `closest`, `strongest`, or `weakest`. Unknown modes and missing ids do nothing. |

`step` during `WAVE`, in order: spawn entries whose tick is due, move every living enemy, resolve combat while the phase is still `WAVE`, then either enter `WAVE_CLEAR` or advance the wave tick. Enemies move on the tick they spawn. Spawn position in the event is the first waypoint, before that tick's move. A leak that sets `DEFEAT` skips combat on that step.

### Placement

`place_tower` succeeds only in `BUILD` or `WAVE`, on an in-bounds buildable cell, for a catalog id listed in `map.unlocked_towers`, when gold covers the tier-0 cost and the cell is empty. It deducts that cost, stores it as `invested`, and returns a new entity id starting at 0. Ids are not reused after a sell. The tower's world position is the cell index (`Vector2(cell)`), the same space enemies walk. Cooldown starts at 0.

`sell_tower` adds `floor(invested * sell_refund)` gold. `invested` is the build cost plus every upgrade paid. With the Normal refund `0.70`, a tier-0 bolt (50) refunds 35. The cell is free afterward. Shells already in flight keep going.

`upgrade_tower` from tier `t` costs `round(base_cost * upgrade_cost_factor * pow(upgrade_cost_growth, t))`. Godot `roundi` rounds halves away from zero, so bolt `t = 0` costs `round(37.5) = 38` and `t = 1` costs `round(58.125) = 58`. Damage becomes `round(base_damage * pow(tier_damage_scale, tier))` (at least 1). Range becomes `base_range * pow(tier_range_scale, tier)`. Bolt tier 1 is damage 16 and range 2.7. Tier 2 is damage 22 and range 2.916. Tiers stop at `max_tier` (2). Cooldown length does not change.

### Combat

```mermaid
sequenceDiagram
  participant Sim as GridwardSim
  Sim->>Sim: tickStatuses
  Sim->>Sim: advanceProjectiles
  Sim->>Sim: towersAcquireAndFire
  Sim->>Sim: removeDead
```

Status ticks run first. Burn deals `stacks * burn_damage_per_stack` with no armor, then every status loses one tick. Shells already in flight move next, at `ProjectileState.SPEED` (6) cells per second. A shell homes on its target while that enemy is alive, then splashes at the impact point. A new shell spawns at the tower cell and does not move until the next combat step.

A tower with `cooldown` 0 and a target fires on that step, then waits `cooldown_ticks` combat steps. Bolt (30) fires on a step and again 30 combat steps later. Cooldown counts down only inside WAVE combat. No target leaves `cooldown` at 0.

Acquire keeps enemies inside range (`distance <= range`), alive, and engageable. Air enemies are engageable only when `anti_air` is set and `ground_only` is clear. Bolt and mortar are ground-only, so they ignore flyers. Flak is anti-air and not ground-only, so it hits flyers and ground. The default mode is `first`.

| Mode | Winner |
|------|--------|
| `first` | Greatest distance along the waypoint polyline |
| `last` | Least distance along the polyline |
| `closest` | Smallest distance to the tower cell |
| `strongest` | Highest current HP |
| `weakest` | Lowest current HP |

Equal metrics keep the lowest entity id.

`hitscan` (bolt, frost, flak) applies damage on the fire step. Frost then applies slow. `projectile` (mortar) flies, then damages every engageable enemy within `splash_radius` of the impact, including the aim point. Full damage, no falloff. Shells do not apply slow or burn. `continuous` (beam) uses the same cooldown and deals its current ramp damage on each shot.

Beam ramp starts at the tier-scaled floor (`damage`) and increases by 1 after each shot, up to the tier-scaled ceiling (`ramp_damage`). Tier 0 is 3, then 4, up through 12. A new target id resets the next shot to the floor. Losing the target without acquiring a new one keeps the stored ramp. The floor and ceiling both use `pow(tier_damage_scale, tier)` from the tier-0 values. Tier 1 is 4 → 16. Tier 2 is 5 → 22.

Each weapon hit subtracts the enemy's armor and deals at least `min_damage`. Bolt against a tank (armor 4) deals 8. Frost against a tank deals 1. HP does not go below 0. A kill removes the enemy, adds `EnemyDef.bounty` once (not scaled by the wave), and emits `enemy_killed`. Entering `WAVE_CLEAR` drops shells still in flight and adds the wave-clear bonus.

Movement uses `speed * (1 - slow)`. Slow magnitude is `min(slow_factor, slow_cap)`. A stronger or equal slow replaces the magnitude and sets `remaining_ticks` to the new duration. A weaker slow leaves the current effect unchanged. Frost is 0.35 for 90 ticks, under the 0.60 cap. The hit's step has already moved; the next `remaining_ticks` moves are slowed.

Burn applies on hitscan and beam hits when `burn_stacks` is above 0. Stacks add up to `burn_max_stacks` (5) and the duration refreshes. No catalog tower sets burn. The DoT on later steps is `stacks * burn_damage_per_stack` and ignores armor.

### Spawn schedule

For each entry, enemy `i` (0-based) is due at `delay_ticks + i * spacing_ticks`. Entries are walked in order. Equal ticks keep that order. When `spawn_jitter_ticks` is greater than 0, each due tick adds `SeededRng.randi_range(-jitter, jitter)` and clamps at 0. The default is 0, so v1 waves do not draw from the generator.

Unknown `enemy_id` values consume the slot and spawn nothing.

### Path and leaks

`EnemyState.advance(distance, waypoints)` walks the polyline. `distance` is `speed * FixedTick.SEC`. When a segment ends, leftover distance continues onto the next segment in the same call. Reaching the last waypoint leaks: the enemy is removed, lives drop by 1 (not below 0), and an `enemy_leaked` event records the new total.

Lives at 0 set `DEFEAT` during that move. That step does not enter `WAVE_CLEAR` or `VICTORY`. Later `step` calls do not move the survivors.

### Wave clear

`WAVE_CLEAR` begins on the step where every slot has spawned and no enemies remain. That step adds `wave_clear_bonus_base + wave_clear_bonus_per_index * wave_index` gold. The following `step()` goes to `BUILD`, starts the intermission timer, and increments `wave_index` when another wave exists, or to `VICTORY` on the last wave. Victory does not start a timer. Payout tables and the Meadow lane-hold loadout are in [balance.md](balance.md). Lane-hold math is `path_coverage_length`, `tower_dps`, `estimated_lane_damage`, and `scaled_enemy_hp`. Upgrade prices go through `upgrade_cost`.

Spawned HP is `maxi(roundi(base_hp * pow(hp_scale, wave_index) * difficulty_hp), 1)` using the sim's config (Normal: `hp_scale` 1.12, `difficulty_hp` 1).

## EnemyState

| Field | Meaning |
|-------|---------|
| `id` | Spawn order, starting at 0 for the match |
| `enemy_id` | `EnemyDef.id` |
| `hp` | Scaled hit points at spawn |
| `speed` | Cells per second before slow, copied from the def |
| `armor` | Subtracted from each weapon hit |
| `is_air` | Flyer flag copied from the def |
| `statuses` | Active `StatusEffect` values |
| `position` | Cell-space point on the polyline |
| `segment` | Waypoint index that starts the current segment |
| `segment_distance` | Cells already traveled on that segment |

`advance(distance: float, waypoints: PackedVector2Array) -> bool` returns true when the enemy has reached the last waypoint.

## TowerState

One placed tower. `damage` and `range` are the tier-scaled stats. `base_damage`, `base_range`, `base_cost`, and `base_ramp` stay at the tier-0 def so later tiers do not compound rounding. `ramp_damage` is the tier-scaled beam ceiling. `beam_damage` is the next beam shot. `focus_id` is the enemy that ramp is tracking, or `-1`. `slow_factor`, `slow_ticks`, `burn_stacks`, and `burn_ticks` are copied from the def at placement. `invested` is gold spent on the build and upgrades. `cooldown` is ticks until the tower may fire. `targeting` is one of `TowerState.TARGET_FIRST`, `TARGET_LAST`, `TARGET_CLOSEST`, `TARGET_STRONGEST`, `TARGET_WEAKEST`.

`is_targeting_mode(mode) -> bool` accepts only those five modes.

## ProjectileState

One shell. `SPEED` is 6 cells per second. `position` and `destination` are cell-space points. `splash_radius` 0 hits only `target_enemy_id`. Copied `damage`, `anti_air`, and `ground_only` stay with the shell after the tower is sold or upgraded.

## StatusEffect

One slow or burn. `kind` is `StatusEffect.SLOW` or `StatusEffect.BURN`. `magnitude` is the slow fraction or the burn stack count. `remaining_ticks` counts down at the start of combat, after movement. `source_id` is the tower entity that applied it.

## GridwardEvents

`type` is a `StringName`.

| Constant | `type` | Fields |
|----------|--------|--------|
| `WAVE_STARTED` | `wave_started` | `wave_index`, `early_bonus` |
| `ENEMY_SPAWNED` | `enemy_spawned` | `id`, `enemy_id`, `position` |
| `ENEMY_LEAKED` | `enemy_leaked` | `id`, `enemy_id`, `lives` |
| `WAVE_CLEARED` | `wave_cleared` | `wave_index`, `bonus`, `gold` |
| `VICTORY` | `victory` | |
| `DEFEAT` | `defeat` | |
| `TOWER_PLACED` | `tower_placed` | `id`, `tower_id`, `cell`, `gold` |
| `TOWER_SOLD` | `tower_sold` | `id`, `refund`, `gold` |
| `TOWER_UPGRADED` | `tower_upgraded` | `id`, `tier`, `cost`, `gold` |
| `TOWER_FIRED` | `tower_fired` | `id`, `tower_id`, `target_id`, `kind` |
| `PROJECTILE_SPAWNED` | `projectile_spawned` | `id`, `tower_entity_id`, `position`, `target_id` |
| `PROJECTILE_IMPACT` | `projectile_impact` | `id`, `position`, `splash_radius` |
| `ENEMY_HIT` | `enemy_hit` | `id`, `damage`, `hp`, `tower_entity_id` |
| `ENEMY_KILLED` | `enemy_killed` | `id`, `enemy_id`, `bounty`, `gold` |

Static helpers with those names build the dictionaries. `position` on a spawn is the first waypoint before movement. `lives` on a leak is the total after that leak. On tower events, `id` is the tower entity id and `gold` is the total after the change. On `tower_fired`, `id` is the tower and `target_id` is the enemy. On projectile events, `id` is the shell. On `enemy_hit` and `enemy_killed`, `id` is the enemy. `hp` is the value after the hit. `bounty` is the catalog bounty added for that kill, and `gold` is the total after the bounty. `early_bonus` on `wave_started` is the early-call gold added for that start (0 on the opening wave). `bonus` on `wave_cleared` is the clear payout, and `gold` is the total after it.

## GridwardConfig

| Field | Normal default | Role |
|-------|----------------|------|
| `hp_scale` | 1.12 | `hp * pow(hp_scale, wave_index)` |
| `sell_refund` | 0.70 | fraction of invested cost |
| `wave_clear_bonus_base` | 25 | clear gold base |
| `wave_clear_bonus_per_index` | 5 | added once per wave index |
| `early_call_ticks_per_gold` | 30 | `floor(remaining_ticks / this)` |
| `early_call_gold_cap` | 40 | early-call gold cap |
| `build_timer_ticks` | 1500 | post-clear intermission; opening build stays at 0 |
| `upgrade_cost_factor` | 0.75 | `round(base_cost * factor * pow(growth, t))` |
| `upgrade_cost_growth` | 1.55 | upgrade curve base |
| `tier_damage_scale` | 1.35 | damage growth per tier above 0 |
| `tier_range_scale` | 1.08 | range growth per tier above 0 |
| `max_tier` | 2 | tiers 0–2 |
| `min_damage` | 1 | damage left after armor |
| `slow_cap` | 0.60 | max slow fraction |
| `burn_max_stacks` | 5 | burn stack cap |
| `burn_damage_per_stack` | 1 | burn damage per tick per stack |
| `spawn_jitter_ticks` | 0 | spawn timing jitter |
| `difficulty_hp` | 1.0 | caller-applied HP multiplier |
| `difficulty_gold` | 1.0 | caller-applied gold multiplier |

Difficulty ids are `easy`, `normal`, and `hard` (`DIFF_EASY`, `DIFF_NORMAL`, `DIFF_HARD`). `for_difficulty(id)` returns a config with the matching multipliers. Unknown ids use Normal.

| Id | `difficulty_hp` | `difficulty_gold` |
|----|-----------------|-------------------|
| easy | 0.85 | 1.15 |
| normal | 1 | 1 |
| hard | 1.25 | 0.9 |

`scaled_gold(amount, difficulty_gold)` is the starting gold for that match. It uses hundredths so Easy 120 becomes 138 and Hard 120 becomes 108. Kill bounty, wave-clear bonus, early call, and sell refund are not multiplied. The sim applies `difficulty_hp` inside `scaled_enemy_hp`. `GridwardSim` builds a Normal config in `_init`. Campaign play assigns `for_difficulty` onto that config before the first step, after scaling `MapDef.starting_gold`.

## MapDef

| Field | Meaning |
|-------|---------|
| `id` | `StringName` |
| `width`, `height` | cell counts |
| `waypoints` | `PackedVector2Array` of cell indices |
| `buildable` | `PackedByteArray`, row-major `y * width + x`, `1` buildable, `0` path |
| `starting_gold`, `starting_lives` | match start |
| `waves` | `Array[WaveDef]` |
| `unlocked_towers` | tower ids the player may place |

`path_cells()` walks the polyline one cell at a time. Orthogonal segments include every cell on the segment. `apply_buildable_off_path()` sets the mask from that walk: path cells are `0`, every other in-bounds cell is `1`. `cell_index(cell)` is `y * width + x`. `is_buildable(cell)` is false outside the map.

### WaveDef entries

Each entry is a `Dictionary`:

| Key | Type |
|-----|------|
| `enemy_id` | `StringName` |
| `count` | `int` |
| `spacing_ticks` | `int` |
| `delay_ticks` | `int` |

Ticks are `FixedTick` steps (1/60 s). Cooldowns and spawn spacing are already in ticks.

## EnemyDef

`speed` is cells per second. Stats are wave-1 Normal, before `hp_scale`.

| Id | HP | Speed | Bounty | Armor | Air | Group | Boss |
|----|----|-------|--------|-------|-----|-------|------|
| grunt | 40 | 1.2 | 8 | 0 | | | |
| runner | 24 | 2.4 | 10 | 0 | | | |
| tank | 120 | 0.7 | 18 | 4 | | | |
| swarm | 12 | 1.8 | 3 | 0 | | yes | |
| flyer | 36 | 1.6 | 14 | 0 | yes | | |
| boss | 800 | 0.55 | 100 | 6 | | | yes |

Published order: `GridwardCatalog.ENEMY_IDS`. A wave entry's `count` is the number of bodies spawned, including swarm. `is_group` does not multiply that count.

## TowerDef

`range` is cells. `kind` is `hitscan`, `projectile`, or `continuous` (`TowerDef.KIND_*`). `splash_radius` 0 is single-target. `slow_factor` 0 means no slow. `ramp_damage` 0 means damage does not ramp; a beam starts at `damage` and ramps to `ramp_damage`. `burn_stacks` 0 means no burn. Catalog towers leave burn at 0.

| Id | Cost | Range | Cooldown | Damage | Kind | Extra |
|----|------|-------|----------|--------|------|-------|
| bolt | 50 | 2.5 | 30 | 12 | hitscan | ground only, starter |
| mortar | 80 | 3.5 | 75 | 28 | projectile | splash 1.2, ground only |
| frost | 70 | 2.2 | 45 | 4 | hitscan | slow 0.35 for 90 ticks, ground only |
| flak | 90 | 3.0 | 24 | 10 | hitscan | anti-air and ground |
| beam | 110 | 2.8 | 6 | 3 → 12 | continuous | ramp, ground only |

Published order: `GridwardCatalog.TOWER_IDS`.

## Meadow

`GridwardCatalog.build_meadow()` returns map id `meadow`.

| Field | Value |
|-------|-------|
| Size | 16×10 |
| Starting gold | 120 |
| Starting lives | 20 |
| Unlocked towers | bolt |
| Waves | 10, grunt and runner only |

Waypoints (cell indices), an orthogonal S from the west edge to the east edge:

`(0, 1) → (12, 1) → (12, 4) → (3, 4) → (3, 7) → (15, 7)`

| Wave | Entries (`enemy_id`, count, spacing_ticks, delay_ticks) |
|------|----------------------------------------------------------|
| 0 | grunt 4 / 70 / 0 |
| 1 | grunt 6 / 60 / 0 |
| 2 | runner 4 / 50 / 0 |
| 3 | grunt 5 / 60 / 0, then runner 3 / 45 / 360 |
| 4 | grunt 5 / 80 / 0 |
| 5 | runner 6 / 40 / 0 |
| 6 | grunt 6 / 50 / 0, then runner 5 / 36 / 320 |
| 7 | grunt 10 / 45 / 0 |
| 8 | runner 8 / 35 / 0 |
| 9 | grunt 8 / 40 / 0, then runner 8 / 30 / 360 |

Waves 0–1 teach the grunt. Wave 2 introduces the runner. Wave 4 is a wider-spaced rest. Wave 9 is the mixed climax. The full enemy and tower tables above still exist on the catalog for later maps.

## Campaign maps

`GridwardCatalog.MAP_IDS` is the unlock order. `build_map(id)` returns one of the builders, or `null`. `map_title` is the label. `star_thresholds` is `(15, 8)` on every map: lives left for 3 stars, then 2 stars. Spawn rows live in the builder. Each map is 16×10 with 20 lives. The path enters on x 0 and leaves on x 15. Path cells are not buildable.

| Map | Id | Waves | Normal gold | Towers | Teach |
|-----|----|-------|-------------|--------|-------|
| Meadow | `meadow` | 10 | 120 | bolt | build and bolt |
| Bend | `bend` | 12 | 150 | bolt, mortar | splash on a tight pack |
| Skyreach | `skyreach` | 12 | 180 | bolt, mortar, flak | flyers |
| Bastion | `bastion` | 14 | 200 | bolt, mortar, frost, flak | armor and slow |
| Citadel | `citadel` | 15 | 240 | all five | boss and beam |

Bend waypoints: `(0, 2) → (11, 2) → (11, 6) → (3, 6) → (3, 8) → (15, 8)`. Wave 2 is a grunt pack at spacing 20. Swarm packs follow. No tank, flyer, or boss.

Skyreach waypoints: `(0, 1) → (15, 1) → (15, 5) → (0, 5) → (0, 8) → (15, 8)`. Wave 2 introduces flyers. No tank or boss.

Bastion waypoints: `(0, 4) → (6, 4) → (6, 1) → (12, 1) → (12, 8) → (4, 8) → (4, 6) → (15, 6)`. Wave 3 introduces tanks. A later wave still sends flyers. No boss.

Citadel waypoints: `(0, 1) → (14, 1) → (14, 3) → (2, 3) → (2, 5) → (14, 5) → (14, 8) → (15, 8)`. Waves revisit splash, air, and armor. Wave 12 sends one boss with a grunt escort. Wave 14 sends the boss again with tank, flyer, and grunt.

Starting gold on Easy and Hard is `scaled_gold` of the Normal value above. The taught tower's cost fits in the Normal purse (mortar 80, flak 90, frost 70, beam 110).

## GridwardProgress

Plain campaign record. No `FileAccess`.

```gdscript
const VERSION := 1
var version: int
var cleared: Dictionary
func stars_for(map_id: StringName, difficulty: StringName) -> int
func best_stars(map_id: StringName) -> int
func is_unlocked(map_id: StringName) -> bool
static func stars_from_lives(lives: int, three_at: int = 15, two_at: int = 8) -> int
func record_victory(map_id: StringName, difficulty: StringName, lives: int, three_at: int = 15, two_at: int = 8) -> int
func capture_state() -> Dictionary
func apply_state(data: Dictionary) -> void
```

`cleared` maps a map id to a difficulty id to a star count. Missing entries are 0. `stars_from_lives` returns 3, 2, 1, or 0 using the gates above. Lives at 0 score 0. `record_victory` returns the stars for this clear and stores the higher of that and the previous count for the same map and difficulty. Unknown difficulty ids are not stored.

`is_unlocked` is true for `meadow`. Each following id in `MAP_IDS` needs `best_stars` of at least 1 on the previous map. Any other id is locked. One star on Easy Meadow opens Bend.

`capture_state` is `{version, cleared}` with string keys `easy`, `normal`, and `hard`. `apply_state` replaces `cleared` from that dictionary. The app migrates before apply. The file format is in [app.md](app.md).

## GridwardBot

```gdscript
func _init(sim: GridwardSim, catalog: GridwardCatalog) -> void
func act() -> void
```

Headless utility player for Meadow on Normal. `act()` does at most one spend, then may call `start_wave`. It uses `place_tower`, `upgrade_tower`, `start_wave`, and the public getters. It does not sell, and it leaves targeting at `first`.

Geometry and unlocks come from `GridwardCatalog.build_meadow()`. Upgrade prices go through `GridwardSim.upgrade_cost` with a Normal `GridwardConfig`. That is the same map and the same defaults `GridwardSim` builds for a Meadow match.

| Step | Rule |
|------|------|
| Early bolts | While fewer than 2 towers are down, place on the buildable cell that adds the most waypoint length inside range. |
| Bolt weight | On waves 0–2, and while fewer than 3 towers exist, bolt is the only type scored when it is affordable. Its score is path length × 1.35. |
| Upgrade | When gold is above 1.5× the next tier cost, upgrade the lowest tier. Ties go to the longer path coverage, then the lower entity id. |
| Later towers | Otherwise place again, up to 6, on a cell that adds at least 2 cells of path no current tower already covers. Skip the buy when gold already covers an upgrade and has not cleared the 1.5× line. |
| Start | In `BUILD`, if none of those spends happen, `start_wave`. Two towers is the defense bar the opening gold can afford. Starting on that tick keeps the early-call bonus. |

`tests/games/gridward/gridward_bot_test.gd` is the balance canary. See [balance.md](balance.md).
