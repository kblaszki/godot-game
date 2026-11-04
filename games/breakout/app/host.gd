extends "res://lab/layered_host.gd"

const MENU_PATH := "res://games/breakout/app/main_menu.tscn"


func _boot() -> void:
	submit(SceneRequest.replace(MENU_PATH))


func _on_quit_requested() -> void:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("return_to_launcher"):
			node.call_deferred("return_to_launcher")
			return
		node = node.get_parent()
	get_tree().quit()
