class_name HoleDef
extends RefCounted

## Flat XZ putt-putt proxy. Positions use Vector3 with y ignored (kept 0).

var id: String = ""
var name: String = ""
var par: int = 3
var tee: Vector3 = Vector3.ZERO
var cup: Vector3 = Vector3.ZERO
## Axis-aligned bounds on XZ: position = min corner (x,z), size = (w,d).
var bounds_min: Vector2 = Vector2.ZERO
var bounds_max: Vector2 = Vector2.ONE
## Each wall: { "a": Vector2, "b": Vector2 }
var walls: Array[Dictionary] = []
## Each blocker: { "center": Vector2, "radius": float }
var blockers: Array[Dictionary] = []
## Each damp pad: { "min": Vector2, "max": Vector2, "factor": float } speed *= factor per second region
var damp_pads: Array[Dictionary] = []


func contains_xz(p: Vector2) -> bool:
	return (
		p.x >= bounds_min.x
		and p.x <= bounds_max.x
		and p.y >= bounds_min.y
		and p.y <= bounds_max.y
	)


func tee_xz() -> Vector2:
	return Vector2(tee.x, tee.z)


func cup_xz() -> Vector2:
	return Vector2(cup.x, cup.z)
