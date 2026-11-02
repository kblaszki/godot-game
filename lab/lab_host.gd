extends "res://lab/layered_host.gd"

const LAUNCHER_PATH := "res://lab/launcher.tscn"
const DEFAULT_SIZE := Vector2i(960, 540)


func _boot() -> void:
	get_window().size = DEFAULT_SIZE
	submit(SceneRequest.replace(LAUNCHER_PATH))


func return_to_launcher() -> void:
	submit(SceneRequest.replace(LAUNCHER_PATH))
	_flush()


func _on_quit_requested() -> void:
	get_tree().quit()
