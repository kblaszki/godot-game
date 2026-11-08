class_name GridwardConfig
extends RefCounted

## Global combat and economy tunables (spec §§5.3, 7).
## Gold, lives, and waves are map data on MapDef. Defaults are Normal difficulty.

## hp * pow(hp_scale, wave_index), wave_index 0-based.
var hp_scale: float = 1.12
## Fraction of invested cost returned on sell.
var sell_refund: float = 0.70
## Wave-clear gold: base + per_index * wave_index.
var wave_clear_bonus_base: int = 25
var wave_clear_bonus_per_index: int = 5
## Early-call gold: min(cap, floor(remaining_ticks / ticks_per_gold)).
var early_call_ticks_per_gold: int = 30
var early_call_gold_cap: int = 40
## Build intermission after a wave clear, in ticks. The opening build has none.
## 1500 ticks is 25 s, so a full timer pays the cap (floor(1500 / 30) = 50).
var build_timer_ticks: int = 1500
## Upgrade cost tier t → t+1: round(base_cost * factor * pow(growth, t)).
var upgrade_cost_factor: float = 0.75
var upgrade_cost_growth: float = 1.55
## Stat growth per tier above tier 0.
var tier_damage_scale: float = 1.35
var tier_range_scale: float = 1.08
## Towers use tiers 0 through max_tier.
var max_tier: int = 2
## Armor subtracts from a hit; remaining damage is at least this.
var min_damage: int = 1
## Slow fraction cap. Strongest slow wins; frosts refresh the duration.
var slow_cap: float = 0.60
var burn_max_stacks: int = 5
## Burn tick damage is stacks * burn_damage_per_stack.
var burn_damage_per_stack: int = 1
## Spawn timing jitter in ticks. Zero keeps v1 waves deterministic.
var spawn_jitter_ticks: int = 0
## Difficulty multipliers applied by the caller. Fields default to Normal.
var difficulty_hp: float = 1.0
var difficulty_gold: float = 1.0

const EASY_HP := 0.85
const EASY_GOLD := 1.15
const NORMAL_HP := 1.0
const NORMAL_GOLD := 1.0
const HARD_HP := 1.25
const HARD_GOLD := 0.9

const DIFF_EASY: StringName = &"easy"
const DIFF_NORMAL: StringName = &"normal"
const DIFF_HARD: StringName = &"hard"
const DIFFICULTIES: Array[StringName] = [DIFF_EASY, DIFF_NORMAL, DIFF_HARD]


static func for_difficulty(difficulty: StringName) -> GridwardConfig:
	var config := GridwardConfig.new()
	match difficulty:
		DIFF_EASY:
			config.difficulty_hp = EASY_HP
			config.difficulty_gold = EASY_GOLD
		DIFF_HARD:
			config.difficulty_hp = HARD_HP
			config.difficulty_gold = HARD_GOLD
		_:
			config.difficulty_hp = NORMAL_HP
			config.difficulty_gold = NORMAL_GOLD
	return config


## Starting gold only. Kill bounty, wave clear, early call, and sell refund stay unscaled.
static func scaled_gold(amount: int, multiplier: float) -> int:
	if amount <= 0 or multiplier <= 0.0:
		return 0
	var hundredths := roundi(multiplier * 100.0)
	return maxi(roundi(float(amount * hundredths) / 100.0), 0)


static func difficulty_title(difficulty: StringName) -> String:
	match difficulty:
		DIFF_EASY:
			return "Easy"
		DIFF_HARD:
			return "Hard"
		_:
			return "Normal"
