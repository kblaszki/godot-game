extends Control

const MAP_SELECT_PATH := "res://games/gridward/app/map_select.tscn"

@onready var _play: Button = $Center/Column/Play
@onready var _quit: Button = $Center/Column/Quit


func _ready() -> void:
	($Center/Column/Hint as Label).text = "Five maps. One star opens the next."
	_play.pressed.connect(_on_play_pressed)
	_quit.pressed.connect(_on_quit_pressed)
	_play.grab_focus()


func _on_play_pressed() -> void:
	_submit(SceneRequest.replace(MAP_SELECT_PATH))


func _on_quit_pressed() -> void:
	_submit(SceneRequest.quit())


func _submit(req: SceneRequest) -> void:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("submit"):
			node.call("submit", req)
			return
		node = node.get_parent()
