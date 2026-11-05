class_name DistrictConfig
extends RefCounted

var start_cash: int = 1500
var go_salary: int = 200
var jail_fine: int = 50
var max_jail_turns: int = 3
var jail_index: int = 8
var tour_index: int = 24
var arena_index: int = 16
var min_players: int = 2
var max_players: int = 4
var table_stake: int = 1
var max_rounds: int = 0
var gadget_uses_per_match: int = 14
var require_monopoly_to_build: bool = true
var arena_ante: int = 50
var steal_cash_amount: int = 100
var parking_collects_tax: bool = false
var spaces: Array[BoardSpace] = []


func _init() -> void:
	spaces = build_default_board()
	jail_index = _find_kind(BoardSpace.KIND_JAIL)
	tour_index = _find_kind(BoardSpace.KIND_TOUR)
	arena_index = _find_kind(BoardSpace.KIND_ARENA)
	apply_stake()


func apply_stake() -> void:
	var m := maxi(table_stake, 1)
	start_cash = 1500 * m
	go_salary = 200 * m
	jail_fine = 50 * m
	arena_ante = 50 * m
	steal_cash_amount = 100 * m


func space_count() -> int:
	return spaces.size()


func space_at(index: int) -> BoardSpace:
	return spaces[index]


func group_spaces(group: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	for i in spaces.size():
		if spaces[i].kind == BoardSpace.KIND_PROPERTY and spaces[i].group == group:
			out.append(i)
	return out


static func build_default_board() -> Array[BoardSpace]:
	## 32 spaces: corners at 0,8,16,24; 7 edge slots per side.
	return [
		BoardSpace.make_go("Plaza Gate"),
		BoardSpace.make_property("Cedar Lane", 0, 60, 6),
		BoardSpace.make_chance("Chance"),
		BoardSpace.make_property("Maple Court", 0, 60, 6),
		BoardSpace.make_tax("City Levy", 100),
		BoardSpace.make_property("Amber Row", 1, 100, 10),
		BoardSpace.make_property("Coral Way", 1, 100, 10),
		BoardSpace.make_property("Ivory Street", 1, 120, 12),
		BoardSpace.make_jail("Lost Island"),
		BoardSpace.make_property("North Quay", 2, 140, 14),
		BoardSpace.make_chance("Chance"),
		BoardSpace.make_property("Harbor Walk", 2, 140, 14),
		BoardSpace.make_property("Pier Eleven", 2, 160, 16),
		BoardSpace.make_tax("Transit Fee", 75),
		BoardSpace.make_property("Glass Mile", 3, 180, 18),
		BoardSpace.make_property("Neon Arcade", 3, 180, 18),
		BoardSpace.make_arena("World Championships"),
		BoardSpace.make_property("Signal Hill", 3, 200, 20),
		BoardSpace.make_chance("Chance"),
		BoardSpace.make_property("Copper Yard", 4, 220, 22),
		BoardSpace.make_property("Iron Bridge", 4, 220, 22),
		BoardSpace.make_property("Steel Spire", 4, 240, 24),
		BoardSpace.make_tax("Luxury Duty", 150, 0.1),
		BoardSpace.make_property("Vista Ridge", 5, 260, 26),
		BoardSpace.make_tour("World Tour"),
		BoardSpace.make_property("Summit Avenue", 5, 260, 26),
		BoardSpace.make_goto_jail("Exile Gate"),
		BoardSpace.make_property("Crown Plaza", 5, 280, 28),
		BoardSpace.make_chance("Chance"),
		BoardSpace.make_property("Obsidian Row", 6, 300, 30),
		BoardSpace.make_property("Aurora Docks", 6, 320, 32),
		BoardSpace.make_property("Eclipse Tower", 6, 350, 40),
	]


func _find_kind(kind: String) -> int:
	for i in spaces.size():
		if spaces[i].kind == kind:
			return i
	return 0
