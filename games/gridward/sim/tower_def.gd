class_name TowerDef
extends RefCounted

const KIND_HITSCAN: StringName = &"hitscan"
const KIND_PROJECTILE: StringName = &"projectile"
const KIND_CONTINUOUS: StringName = &"continuous"

## Tier-0 tower stats. Upgrade curves live on GridwardConfig.

var id: StringName = &""
var cost: int = 0
## Attack range in cells.
var range: float = 0.0
var cooldown_ticks: int = 0
## Hitscan and projectile damage, or the starting damage of a ramping beam.
var damage: int = 0
var kind: StringName = KIND_HITSCAN
## Splash radius in cells. Zero means a single target.
var splash_radius: float = 0.0
## Fraction of speed removed while slowed. Zero means no slow.
var slow_factor: float = 0.0
var slow_ticks: int = 0
var anti_air: bool = false
## When true, the tower engages ground targets only.
var ground_only: bool = true
## Beam damage ramps from damage up to this value. Zero means no ramp.
var ramp_damage: int = 0
