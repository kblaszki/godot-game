class_name PlayerScore
extends RefCounted

var is_bot: bool = false
var hole_strokes: PackedInt32Array = PackedInt32Array()
var finished_hole: bool = false


func _init(p_is_bot: bool = false, hole_count: int = 9) -> void:
	is_bot = p_is_bot
	hole_strokes.resize(hole_count)
	for i in hole_count:
		hole_strokes[i] = 0


func total() -> int:
	var sum := 0
	for i in hole_strokes.size():
		sum += hole_strokes[i]
	return sum


func hole_in_ones() -> int:
	var n := 0
	for i in hole_strokes.size():
		if hole_strokes[i] == 1:
			n += 1
	return n
