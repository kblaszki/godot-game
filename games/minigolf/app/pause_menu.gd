extends Control

const MENU_PATH := "res://games/minigolf/app/menu.tscn"

@onready var _resume: Button = $Center/Column/Resume
@onready var _quit: Button = $Center/Column/Quit


func _ready() -> void:
	_resume.pressed.connect(func() -> void: _submit(SceneRequest.pop()))
	_quit.pressed.connect(func() -> void: _submit(SceneRequest.replace(MENU_PATH)))
	_resume.grab_focus()


func _submit(req: SceneRequest) -> void:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("submit"):
			node.call("submit", req)
			return
		node = node.get_parent()
