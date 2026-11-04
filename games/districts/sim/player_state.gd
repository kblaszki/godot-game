class_name PlayerState
extends RefCounted

var cash: int = 0
var position: int = 0
var in_jail: bool = false
var jail_turns: int = 0
var owned: PackedInt32Array = PackedInt32Array()
var bankrupt: bool = false
var is_bot: bool = false


func _init(p_cash: int = 0, p_is_bot: bool = false) -> void:
	cash = p_cash
	is_bot = p_is_bot


func owns(space_index: int) -> bool:
	for i in owned.size():
		if owned[i] == space_index:
			return true
	return false


func add_owned(space_index: int) -> void:
	if not owns(space_index):
		owned.append(space_index)


func clear_owned() -> void:
	owned = PackedInt32Array()
