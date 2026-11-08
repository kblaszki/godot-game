extends Control

const PLAY_PATH := "res://games/gridward/app/play.tscn"

@onready var _play: Button = $Center/Column/Play
@onready var _quit: Button = $Center/Column/Quit


func _ready() -> void:
	_play.pressed.connect(_on_play_pressed)
	_quit.pressed.connect(_on_quit_pressed)
	_play.grab_focus()


func _on_play_pressed() -> void:
	_submit(SceneRequest.replace(PLAY_PATH))


func _on_quit_pressed() -> void:
	_submit(SceneRequest.quit())


func _submit(req: SceneRequest) -> void:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("submit"):
			node.call("submit", req)
			return
		node = node.get_parent()
