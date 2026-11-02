extends "res://lab/layered_host.gd"

const MENU_PATH := "res://games/pong/app/main_menu.tscn"


func _boot() -> void:
	var config := PongConfig.new()
	get_window().size = Vector2i(int(config.court_width), int(config.court_height))
	submit(SceneRequest.replace(MENU_PATH))


func _on_quit_requested() -> void:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("return_to_launcher"):
			# Defer so this host is not freed mid-_flush.
			node.call_deferred("return_to_launcher")
			return
		node = node.get_parent()
	get_tree().quit()
