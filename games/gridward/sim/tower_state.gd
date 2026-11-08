class_name TowerState
extends RefCounted

## One placed tower. Combat stats are the tier-scaled copy used by GridwardSim.

const TARGET_FIRST: StringName = &"first"
const TARGET_LAST: StringName = &"last"
const TARGET_CLOSEST: StringName = &"closest"
const TARGET_STRONGEST: StringName = &"strongest"
const TARGET_WEAKEST: StringName = &"weakest"

var id: int = 0
var tower_id: StringName = &""
var cell: Vector2i = Vector2i.ZERO
var tier: int = 0
## Gold spent on the build and every upgrade. Sell refunds a fraction of this.
var invested: int = 0
var base_cost: int = 0
var base_damage: int = 0
var base_range: float = 0.0
## Damage and range at the current tier.
var damage: int = 0
var range: float = 0.0
var cooldown_ticks: int = 0
## Ticks remaining before the next shot. Zero means ready.
var cooldown: int = 0
var kind: StringName = TowerDef.KIND_HITSCAN
var splash_radius: float = 0.0
var anti_air: bool = false
var ground_only: bool = true
var targeting: StringName = TARGET_FIRST


static func is_targeting_mode(mode: StringName) -> bool:
	return (
		mode == TARGET_FIRST
		or mode == TARGET_LAST
		or mode == TARGET_CLOSEST
		or mode == TARGET_STRONGEST
		or mode == TARGET_WEAKEST
	)
