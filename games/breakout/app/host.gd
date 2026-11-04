extends "res://lab/layered_host.gd"

const MENU_PATH := "res://games/breakout/app/main_menu.tscn"

var _audio: GodotAudio


func _boot() -> void:
	_audio = GodotAudio.new()
	add_child(_audio)
	_audio.register_blip(&"brick", 880.0, 0.04)
	_audio.register_blip(&"die", 140.0, 0.2)
	_audio.register_blip(&"clear", 1200.0, 0.16)
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
