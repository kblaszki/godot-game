class_name PlayerState
extends RefCounted

var cash: int = 0
var position: int = 0
var in_jail: bool = false
var jail_turns: int = 0
var owned: PackedInt32Array = PackedInt32Array()
## Build level per owned space index (parallel to board; 0 = undeveloped).
var build_levels: Dictionary = {}
var bankrupt: bool = false
var is_bot: bool = false
var frozen_turns: int = 0
var shield_charges: int = 0
var double_rent_charges: int = 0
var get_out_cards: int = 0
var vip: bool = false
## gadget_id -> count in inventory
var gadgets: Dictionary = {}


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
		build_levels[space_index] = 0


func remove_owned(space_index: int) -> void:
	var next := PackedInt32Array()
	for i in owned.size():
		if owned[i] != space_index:
			next.append(owned[i])
	owned = next
	build_levels.erase(space_index)


func clear_owned() -> void:
	owned = PackedInt32Array()
	build_levels.clear()


func get_build_level(space_index: int) -> int:
	return int(build_levels.get(space_index, 0))


func set_build_level(space_index: int, level: int) -> void:
	build_levels[space_index] = level


func add_gadget(gadget_id: String, count: int = 1) -> void:
	gadgets[gadget_id] = int(gadgets.get(gadget_id, 0)) + count


func consume_gadget(gadget_id: String) -> bool:
	var n := int(gadgets.get(gadget_id, 0))
	if n <= 0:
		return false
	if n == 1:
		gadgets.erase(gadget_id)
	else:
		gadgets[gadget_id] = n - 1
	return true
