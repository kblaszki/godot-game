extends "res://lab/layered_host.gd"

const LAUNCHER_PATH := "res://lab/launcher.tscn"


func _boot() -> void:
	var settings := SettingsStore.load(SettingsStore.DEFAULT_PATH)
	WindowApplier.apply(settings, get_window())
	submit(SceneRequest.replace(LAUNCHER_PATH))


func return_to_launcher() -> void:
	submit(SceneRequest.replace(LAUNCHER_PATH))
	_flush()


func _on_quit_requested() -> void:
	get_tree().quit()
