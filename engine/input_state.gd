class_name InputState
extends RefCounted

var _held: Dictionary = {}
var _just_pressed: Dictionary = {}
var _just_released: Dictionary = {}


func begin_frame() -> void:
	_just_pressed.clear()
	_just_released.clear()


func set_action(name: StringName, held: bool) -> void:
	var was_held := bool(_held.get(name, false))
	_held[name] = held
	if held and not was_held:
		_just_pressed[name] = true
		_just_released.erase(name)
	elif not held and was_held:
		_just_released[name] = true
		_just_pressed.erase(name)


func is_action_pressed(name: StringName) -> bool:
	return bool(_held.get(name, false))


func is_action_just_pressed(name: StringName) -> bool:
	return bool(_just_pressed.get(name, false))


func is_action_just_released(name: StringName) -> bool:
	return bool(_just_released.get(name, false))


func get_axis(negative: StringName, positive: StringName) -> float:
	var neg := is_action_pressed(negative)
	var pos := is_action_pressed(positive)
	if neg == pos:
		return 0.0
	if neg:
		return -1.0
	return 1.0
