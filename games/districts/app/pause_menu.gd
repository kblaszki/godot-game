extends Control

const SETUP_PATH := "res://games/districts/app/setup.tscn"

@onready var _panel: PanelContainer = $Center/Panel
@onready var _resume: Button = $Center/Panel/Margin/Column/Resume
@onready var _quit_menu: Button = $Center/Panel/Margin/Column/QuitToMenu


func _ready() -> void:
	_apply_styles()
	_resume.pressed.connect(func() -> void: _submit(SceneRequest.pop()))
	_quit_menu.pressed.connect(_on_quit)
	_resume.grab_focus()
	_panel.modulate.a = 0.0
	await get_tree().process_frame
	_panel.pivot_offset = _panel.size * 0.5
	_panel.scale = Vector2(0.92, 0.92)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.16)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _apply_styles() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.08, 0.1, 0.14, 0.97)
	panel.set_border_width_all(1)
	panel.border_color = Color(1, 1, 1, 0.1)
	panel.set_corner_radius_all(14)
	_panel.add_theme_stylebox_override("panel", panel)
	_style_button(_resume, Color(0.18, 0.55, 0.42, 1), true)
	_style_button(_quit_menu, Color(0.22, 0.25, 0.32, 1), false)


func _style_button(btn: Button, color: Color, emphasize: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.set_corner_radius_all(10)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	if emphasize:
		normal.set_border_width_all(1)
		normal.border_color = Color(1, 1, 1, 0.18)
	var hover := normal.duplicate()
	hover.bg_color = color.lightened(0.12)
	var pressed := normal.duplicate()
	pressed.bg_color = color.darkened(0.12)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", Color(0.95, 0.97, 1, 1))


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
