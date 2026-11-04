extends Control

## Registry of playable games for the lab shell. Add a row per new game host.
const GAMES := [
	{"title": "Pong", "host_path": "res://games/pong/app/host.tscn"},
	{"title": "Snake", "host_path": "res://games/snake/app/host.tscn"},
	{"title": "Shatter", "host_path": "res://games/breakout/app/host.tscn"},
	{"title": "Districts", "host_path": "res://games/districts/app/host.tscn"},
]
const SETTINGS_PATH := "res://lab/settings.tscn"

@onready var _column: VBoxContainer = $Center/Column


func _ready() -> void:
	for entry in GAMES:
		var button := Button.new()
		button.custom_minimum_size = Vector2(280, 44)
		button.text = str(entry["title"])
		var path := str(entry["host_path"])
		button.pressed.connect(_on_game_pressed.bind(path))
		_column.add_child(button)
		if _column.get_child_count() == 3:
			# Title + Hint are first; first game button gets focus.
			button.grab_focus()
	var settings := Button.new()
	settings.custom_minimum_size = Vector2(280, 44)
	settings.text = "Settings"
	settings.pressed.connect(_on_settings_pressed)
	_column.add_child(settings)
	var quit := Button.new()
	quit.custom_minimum_size = Vector2(280, 44)
	quit.text = "Quit"
	quit.pressed.connect(_on_quit_pressed)
	_column.add_child(quit)


func _on_game_pressed(host_path: String) -> void:
	_submit(SceneRequest.replace(host_path))


func _on_settings_pressed() -> void:
	_submit(SceneRequest.replace(SETTINGS_PATH))


func _on_quit_pressed() -> void:
	_submit(SceneRequest.quit())


func _submit(req: SceneRequest) -> void:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("submit"):
			node.call("submit", req)
			return
		node = node.get_parent()
