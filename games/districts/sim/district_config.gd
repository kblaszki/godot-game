class_name DistrictConfig
extends RefCounted

var start_cash: int = 1500
var go_salary: int = 200
var jail_fine: int = 50
var max_jail_turns: int = 3
var jail_index: int = 7
var min_players: int = 2
var max_players: int = 4
var spaces: Array[BoardSpace] = []


func _init() -> void:
	spaces = build_default_board()
	jail_index = _find_kind(BoardSpace.KIND_JAIL)


func space_count() -> int:
	return spaces.size()


func space_at(index: int) -> BoardSpace:
	return spaces[index]


static func build_default_board() -> Array[BoardSpace]:
	var board: Array[BoardSpace] = [
		BoardSpace.make_go("Plaza Gate"),
		BoardSpace.make_property("Cedar Lane", 0, 60, 6),
		BoardSpace.make_property("Maple Court", 0, 60, 6),
		BoardSpace.make_tax("City Levy", 100),
		BoardSpace.make_property("Amber Row", 1, 100, 10),
		BoardSpace.make_property("Coral Way", 1, 100, 10),
		BoardSpace.make_property("Ivory Street", 1, 120, 12),
		BoardSpace.make_jail("Holding"),
		BoardSpace.make_property("North Quay", 2, 140, 14),
		BoardSpace.make_property("Harbor Walk", 2, 140, 14),
		BoardSpace.make_property("Pier Eleven", 2, 160, 16),
		BoardSpace.make_tax("Transit Fee", 75),
		BoardSpace.make_property("Glass Mile", 3, 180, 18),
		BoardSpace.make_property("Neon Arcade", 3, 180, 18),
		BoardSpace.make_free("Sky Park"),
		BoardSpace.make_property("Signal Hill", 3, 200, 20),
		BoardSpace.make_property("Copper Yard", 4, 220, 22),
		BoardSpace.make_property("Iron Bridge", 4, 220, 22),
		BoardSpace.make_property("Steel Spire", 4, 240, 24),
		BoardSpace.make_tax("Luxury Duty", 150),
		BoardSpace.make_property("Vista Ridge", 5, 260, 26),
		BoardSpace.make_goto_jail("Exile Gate"),
		BoardSpace.make_property("Summit Avenue", 5, 260, 26),
		BoardSpace.make_property("Crown Plaza", 5, 280, 28),
		BoardSpace.make_property("Obsidian Row", 6, 300, 30),
		BoardSpace.make_property("Aurora Docks", 6, 300, 30),
		BoardSpace.make_property("Eclipse Tower", 6, 320, 32),
		BoardSpace.make_property("Midnight Hub", 6, 350, 40),
	]
	return board


func _find_kind(kind: String) -> int:
	for i in spaces.size():
		if spaces[i].kind == kind:
			return i
	return 0
