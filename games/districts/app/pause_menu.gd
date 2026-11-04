extends Control

const SETUP_PATH := "res://games/districts/app/setup.tscn"

@onready var _resume: Button = $Center/Column/Resume
@onready var _quit_menu: Button = $Center/Column/QuitToMenu


func _ready() -> void:
	_resume.pressed.connect(func() -> void: _submit(SceneRequest.pop()))
	_quit_menu.pressed.connect(_on_quit)
	_resume.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_submit(SceneRequest.pop())
		get_viewport().set_input_as_handled()


func _on_quit() -> void:
	_submit(SceneRequest.pop())
	_submit(SceneRequest.replace(SETUP_PATH))


func _submit(req: SceneRequest) -> void:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("submit"):
			node.call("submit", req)
			return
		node = node.get_parent()
