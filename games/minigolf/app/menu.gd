extends Control

const SETUP_PATH := "res://games/minigolf/app/setup.tscn"

@onready var _start: Button = $Center/Column/Start
@onready var _quit: Button = $Center/Column/Quit
@onready var _title: Label = $Center/Column/Title


func _ready() -> void:
	_title.text = "Fairway Circuit"
	_start.pressed.connect(func() -> void: _submit(SceneRequest.replace(SETUP_PATH)))
	_quit.pressed.connect(func() -> void: _submit(SceneRequest.quit()))
	_start.grab_focus()


func _submit(req: SceneRequest) -> void:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("submit"):
			node.call("submit", req)
			return
		node = node.get_parent()
