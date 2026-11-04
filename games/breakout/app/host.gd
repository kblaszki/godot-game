extends "res://lab/layered_host.gd"

const MENU_PATH := "res://games/breakout/app/main_menu.tscn"

var _audio: GodotAudio


func _boot() -> void:
	_audio = GodotAudio.new()
	add_child(_audio)
	_audio.register_blip(&"brick", 720.0, 0.05)
	_audio.register_blip(&"die", 180.0, 0.16)
	_audio.register_blip(&"clear", 980.0, 0.12)
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
