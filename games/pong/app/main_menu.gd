extends Control

const PLAY_PATH := "res://games/pong/app/play.tscn"

@onready var _start: Button = $Center/Column/Start
@onready var _quit: Button = $Center/Column/Quit


func _ready() -> void:
	_start.pressed.connect(_on_start_pressed)
	_quit.pressed.connect(_on_quit_pressed)
	_start.grab_focus()


func _on_start_pressed() -> void:
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
