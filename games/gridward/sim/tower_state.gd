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
var slow_factor: float = 0.0
var slow_ticks: int = 0
## Tier-0 beam ceiling. Zero means this tower does not ramp.
var base_ramp: int = 0
## Beam ceiling at the current tier.
var ramp_damage: int = 0
## Next beam shot. Resets to `damage` when the focus changes.
var beam_damage: int = 0
## Enemy entity the beam is ramping on, or -1.
var focus_id: int = -1
var burn_stacks: int = 0
var burn_ticks: int = 0
var targeting: StringName = TARGET_FIRST


static func is_targeting_mode(mode: StringName) -> bool:
	return (
		mode == TARGET_FIRST
		or mode == TARGET_LAST
		or mode == TARGET_CLOSEST
		or mode == TARGET_STRONGEST
		or mode == TARGET_WEAKEST
	)
