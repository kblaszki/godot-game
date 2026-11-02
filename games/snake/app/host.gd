extends "res://lab/layered_host.gd"

const MENU_PATH := "res://games/snake/app/main_menu.tscn"

var _audio: GodotAudio


func _boot() -> void:
	_audio = GodotAudio.new()
	add_child(_audio)
	_audio.register_blip(&"eat", 880.0, 0.06)
	_audio.register_blip(&"die", 220.0, 0.18)
	var config := SnakeConfig.new()
	var size := Vector2i(
		int(config.width * config.cell),
		int(config.height * config.cell) + 48
	)
	get_window().size = size
	submit(SceneRequest.replace(MENU_PATH))


func get_audio() -> GodotAudio:
	return _audio


func _on_quit_requested() -> void:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("return_to_launcher"):
			node.call_deferred("return_to_launcher")
			return
		node = node.get_parent()
	get_tree().quit()
