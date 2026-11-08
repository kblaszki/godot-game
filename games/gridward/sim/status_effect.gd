class_name StatusEffect
extends RefCounted

## One slow or burn on an enemy. GridwardSim owns the tick rules.

const SLOW: StringName = &"slow"
const BURN: StringName = &"burn"

var kind: StringName = &""
## Slow fraction after the cap, or burn stack count.
var magnitude: float = 0.0
var remaining_ticks: int = 0
## Tower entity that applied the effect, or -1.
var source_id: int = -1
