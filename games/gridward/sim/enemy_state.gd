class_name EnemyState
extends RefCounted

## One enemy walking a waypoint polyline. Distance is in cells.

var id: int = 0
var enemy_id: StringName = &""
var hp: int = 0
## Cells per second.
var speed: float = 0.0
## Position in cell space.
var position: Vector2 = Vector2.ZERO
## Waypoint index at the start of the current segment.
var segment: int = 0
## Distance already traveled along the current segment, in cells.
var segment_distance: float = 0.0


## Advances `distance` cells. Leftover distance continues onto the next segment
## in the same call. Returns true when the enemy reaches the last waypoint.
func advance(distance: float, waypoints: PackedVector2Array) -> bool:
	if waypoints.size() < 2:
		if not waypoints.is_empty():
			position = waypoints[0]
		return true
	var remaining := maxf(distance, 0.0)
	while remaining > 0.0:
		if segment >= waypoints.size() - 1:
			position = waypoints[waypoints.size() - 1]
			segment_distance = 0.0
			return true
		var start: Vector2 = waypoints[segment]
		var finish: Vector2 = waypoints[segment + 1]
		var delta := finish - start
		var length := delta.length()
		if length <= 0.0000001:
			segment += 1
			segment_distance = 0.0
			position = finish
			continue
		var room := length - segment_distance
		if remaining < room:
			segment_distance += remaining
			remaining = 0.0
			position = start + delta * (segment_distance / length)
		else:
			remaining -= room
			segment += 1
			segment_distance = 0.0
			position = finish
	return segment >= waypoints.size() - 1
