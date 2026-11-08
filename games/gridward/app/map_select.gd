extends Control

const PLAY_PATH := "res://games/gridward/app/play.tscn"
const MENU_PATH := "res://games/gridward/app/menu.tscn"

var _map_buttons: Array[Button] = []

@onready var _easy: Button = $Center/Column/Difficulty/Easy
@onready var _normal: Button = $Center/Column/Difficulty/Normal
@onready var _hard: Button = $Center/Column/Difficulty/Hard
@onready var _maps: VBoxContainer = $Center/Column/Maps
@onready var _start: Button = $Center/Column/Start
@onready var _back: Button = $Center/Column/Back


func _ready() -> void:
	var group := ButtonGroup.new()
	group.allow_unpress = false
	for button in [_easy, _normal, _hard]:
		button.toggle_mode = true
		button.button_group = group
	_build_maps()
	_restore_choice()
	_start.pressed.connect(_on_start)
	_back.pressed.connect(_on_back)
	_wire_focus()
	_focus_map()


func _build_maps() -> void:
	var group := ButtonGroup.new()
	group.allow_unpress = false
	var progress := _progress()
	for map_id in GridwardCatalog.MAP_IDS:
		var button := Button.new()
		button.name = GridwardCatalog.map_title(map_id)
		button.toggle_mode = true
		button.button_group = group
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(280, 44)
		button.set_meta("map_id", map_id)
		var unlocked := progress.is_unlocked(map_id)
		button.disabled = not unlocked
		if unlocked:
			button.text = "%s   %s" % [button.name, _star_label(progress.best_stars(map_id))]
		else:
			button.text = "%s   locked" % button.name
		_maps.add_child(button)
		_map_buttons.append(button)
	if not _map_buttons.is_empty():
		_map_buttons[0].button_pressed = true


func _restore_choice() -> void:
	var host := _find_host()
	var difficulty: StringName = GridwardConfig.DIFF_NORMAL
	var map_id: StringName = GridwardCatalog.MEADOW
	if host != null:
		var chosen_diff = host.get("selected_difficulty")
		var chosen_map = host.get("selected_map")
		if chosen_diff != null:
			difficulty = chosen_diff
		if chosen_map != null:
			map_id = chosen_map
	_easy.button_pressed = difficulty == GridwardConfig.DIFF_EASY
	_hard.button_pressed = difficulty == GridwardConfig.DIFF_HARD
	if not _easy.button_pressed and not _hard.button_pressed:
		_normal.button_pressed = true
	if not _progress().is_unlocked(map_id):
		map_id = GridwardCatalog.MEADOW
	for button in _map_buttons:
		if button.get_meta("map_id") == map_id and not button.disabled:
			button.button_pressed = true
			return


func _on_start() -> void:
	var map_id := _chosen_map()
	var difficulty := _chosen_difficulty()
	for button in _map_buttons:
		if button.button_pressed and button.disabled:
			return
	var host := _find_host()
	if host == null:
		return
	var progress = host.get("progress")
	if progress is GridwardProgress and not (progress as GridwardProgress).is_unlocked(map_id):
		return
	if host.has_method("choose_match"):
		host.call("choose_match", map_id, difficulty)
	_submit(SceneRequest.replace(PLAY_PATH))


func _on_back() -> void:
	_submit(SceneRequest.replace(MENU_PATH))


func _chosen_map() -> StringName:
	for button in _map_buttons:
		if button.button_pressed:
			return button.get_meta("map_id")
	return GridwardCatalog.MEADOW


func _chosen_difficulty() -> StringName:
	if _easy.button_pressed:
		return GridwardConfig.DIFF_EASY
	if _hard.button_pressed:
		return GridwardConfig.DIFF_HARD
	return GridwardConfig.DIFF_NORMAL


func _progress() -> GridwardProgress:
	var host := _find_host()
	if host != null:
		var found = host.get("progress")
		if found is GridwardProgress:
			return found
	return GridwardProgress.new()


func _wire_focus() -> void:
	var diffs: Array[Button] = [_easy, _normal, _hard]
	for i in diffs.size():
		if i > 0:
			diffs[i].focus_neighbor_left = diffs[i - 1].get_path()
		if i + 1 < diffs.size():
			diffs[i].focus_neighbor_right = diffs[i + 1].get_path()
		if not _map_buttons.is_empty():
			diffs[i].focus_neighbor_bottom = _map_buttons[0].get_path()
	for i in _map_buttons.size():
		if i == 0:
			_map_buttons[i].focus_neighbor_top = _normal.get_path()
		else:
			_map_buttons[i].focus_neighbor_top = _map_buttons[i - 1].get_path()
		if i + 1 < _map_buttons.size():
			_map_buttons[i].focus_neighbor_bottom = _map_buttons[i + 1].get_path()
		else:
			_map_buttons[i].focus_neighbor_bottom = _start.get_path()
	if not _map_buttons.is_empty():
		_start.focus_neighbor_top = _map_buttons[_map_buttons.size() - 1].get_path()
	_start.focus_neighbor_bottom = _back.get_path()
	_back.focus_neighbor_top = _start.get_path()


func _focus_map() -> void:
	for button in _map_buttons:
		if button.button_pressed and not button.disabled:
			button.grab_focus()
			return
	_start.grab_focus()


func _star_label(count: int) -> String:
	var text := ""
	var filled := clampi(count, 0, 3)
	for i in 3:
		text += "★" if i < filled else "☆"
	return text


func _find_host() -> Node:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("choose_match") and node.has_method("note_result"):
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
