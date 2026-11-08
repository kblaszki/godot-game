extends "res://lab/layered_host.gd"

const MENU_PATH := "res://games/gridward/app/menu.tscn"

var progress_path: String = GridwardProgressStore.DEFAULT_PATH
var progress: GridwardProgress = GridwardProgress.new()
var selected_map: StringName = GridwardCatalog.MEADOW
var selected_difficulty: StringName = GridwardConfig.DIFF_NORMAL


func _boot() -> void:
	progress_path = _progress_path_from_parents()
	progress = GridwardProgressStore.load(progress_path)
	submit(SceneRequest.replace(MENU_PATH))


func choose_match(map_id: StringName, difficulty: StringName) -> void:
	selected_map = map_id
	selected_difficulty = difficulty


## Records a finished match. Victory keeps the best stars and writes the save.
func note_result(map_id: StringName, difficulty: StringName, lives: int, won: bool) -> int:
	var earned := 0
	if won:
		var gates := GridwardCatalog.star_thresholds(map_id)
		earned = progress.record_victory(map_id, difficulty, lives, gates.x, gates.y)
		GridwardProgressStore.save(progress_path, progress)
	set_meta("result_map", map_id)
	set_meta("result_difficulty", difficulty)
	set_meta("result_lives", lives)
	set_meta("result_won", won)
	set_meta("result_stars", earned)
	return earned


func _progress_path_from_parents() -> String:
	var node: Node = get_parent()
	while node != null:
		if node.has_meta("gridward_progress_path"):
			return str(node.get_meta("gridward_progress_path"))
		node = node.get_parent()
	return GridwardProgressStore.DEFAULT_PATH


func _on_quit_requested() -> void:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("return_to_launcher"):
			# Defer so this host is not freed mid-_flush.
			node.call_deferred("return_to_launcher")
			return
		node = node.get_parent()
	get_tree().quit()
