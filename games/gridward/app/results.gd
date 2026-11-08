extends Control

const MAP_SELECT_PATH := "res://games/gridward/app/map_select.tscn"
const MENU_PATH := "res://games/gridward/app/menu.tscn"

@onready var _title: Label = $Center/Column/Title
@onready var _stars: Label = $Center/Column/Stars
@onready var _detail: Label = $Center/Column/Detail
@onready var _map_select: Button = $Center/Column/MapSelect
@onready var _menu: Button = $Center/Column/Menu


func _ready() -> void:
	_title.text = "Match over"
	_stars.text = "No stars"
	_detail.text = ""
	var host := _find_host()
	if host != null and host.has_meta("result_won"):
		var won := bool(host.get_meta("result_won"))
		var lives := int(host.get_meta("result_lives", 0))
		var earned := int(host.get_meta("result_stars", 0))
		var map_id: StringName = host.get_meta("result_map", &"")
		var difficulty: StringName = host.get_meta("result_difficulty", &"normal")
		_title.text = "Victory" if won else "Defeat"
		_stars.text = _star_label(earned) if won else "No stars"
		_detail.text = "%s · %s · %d lives" % [
			GridwardCatalog.map_title(map_id),
			GridwardConfig.difficulty_title(difficulty),
			lives,
		]
	_map_select.pressed.connect(func() -> void: _submit(SceneRequest.replace(MAP_SELECT_PATH)))
	_menu.pressed.connect(func() -> void: _submit(SceneRequest.replace(MENU_PATH)))
	_map_select.focus_neighbor_bottom = _menu.get_path()
	_menu.focus_neighbor_top = _map_select.get_path()
	_map_select.grab_focus()


func _star_label(count: int) -> String:
	var text := ""
	var filled := clampi(count, 0, 3)
	for i in 3:
		text += "★" if i < filled else "☆"
	return text


func _find_host() -> Node:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("note_result"):
			return node
		node = node.get_parent()
	return null


func _submit(req: SceneRequest) -> void:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("submit"):
			node.call("submit", req)
			return
		node = node.get_parent()
