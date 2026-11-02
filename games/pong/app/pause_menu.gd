extends Control

const MENU_PATH := "res://games/pong/app/main_menu.tscn"

@onready var _resume: Button = $Center/Column/Resume
@onready var _quit_menu: Button = $Center/Column/QuitToMenu


func _ready() -> void:
	_resume.pressed.connect(_on_resume_pressed)
	_quit_menu.pressed.connect(_on_quit_to_menu_pressed)
	_resume.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pong_pause") or event.is_action_pressed("ui_cancel"):
		_on_resume_pressed()
		get_viewport().set_input_as_handled()


func _on_resume_pressed() -> void:
	_submit(SceneRequest.pop())


func _on_quit_to_menu_pressed() -> void:
	# POP removes pause, REPLACE swaps play for menu (batch in one flush).
	_submit(SceneRequest.pop())
	_submit(SceneRequest.replace(MENU_PATH))


func _submit(req: SceneRequest) -> void:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("submit"):
			node.call("submit", req)
			return
		node = node.get_parent()
