extends Control

const PLAY_PATH := "res://games/districts/app/play.tscn"
const SEAT_COLORS: Array[Color] = [
	Color(0.95, 0.45, 0.4, 1),
	Color(0.4, 0.75, 1.0, 1),
	Color(0.45, 0.9, 0.55, 1),
	Color(0.95, 0.8, 0.35, 1),
]

var _player_count: int = 2
var _bot_flags: Array[bool] = [false, true, true, true]

@onready var _panel: PanelContainer = $Center/Panel
@onready var _count_label: Label = $Center/Panel/Margin/Column/CountRow/Count
@onready var _minus: Button = $Center/Panel/Margin/Column/CountRow/Minus
@onready var _plus: Button = $Center/Panel/Margin/Column/CountRow/Plus
@onready var _seats: VBoxContainer = $Center/Panel/Margin/Column/Seats
@onready var _start: Button = $Center/Panel/Margin/Column/Start
@onready var _quit: Button = $Center/Panel/Margin/Column/Quit


func _ready() -> void:
	_apply_styles()
	_minus.pressed.connect(_on_minus)
	_plus.pressed.connect(_on_plus)
	_start.pressed.connect(_on_start)
	_quit.pressed.connect(_on_quit)
	_rebuild_seats()
	_start.grab_focus()
	_panel.modulate.a = 0.0
	await get_tree().process_frame
	_panel.pivot_offset = _panel.size * 0.5
	_panel.scale = Vector2(0.94, 0.94)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.22)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _apply_styles() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.08, 0.1, 0.14, 0.97)
	panel.set_border_width_all(1)
	panel.border_color = Color(1, 1, 1, 0.08)
	panel.set_corner_radius_all(16)
	_panel.add_theme_stylebox_override("panel", panel)
	_style_button(_minus, Color(0.18, 0.22, 0.28, 1), false)
	_style_button(_plus, Color(0.18, 0.22, 0.28, 1), false)
	_style_button(_start, Color(0.18, 0.55, 0.42, 1), true)
	_style_button(_quit, Color(0.2, 0.23, 0.28, 1), false)


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
	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.15, 0.17, 0.2, 1)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", Color(0.95, 0.97, 1, 1))
	btn.add_theme_color_override("font_disabled_color", Color(0.45, 0.5, 0.55, 1))


func _on_minus() -> void:
	_player_count = maxi(2, _player_count - 1)
	_rebuild_seats()


func _on_plus() -> void:
	_player_count = mini(4, _player_count + 1)
	_rebuild_seats()


func _rebuild_seats() -> void:
	_count_label.text = str(_player_count)
	for child in _seats.get_children():
		child.queue_free()
	for i in _player_count:
		var card := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.14, 0.18, 1)
		style.set_corner_radius_all(8)
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", style)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(10, 28)
		swatch.color = SEAT_COLORS[i % SEAT_COLORS.size()]
		var label := Label.new()
		label.text = "Seat %d" % (i + 1)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_color_override("font_color", Color(0.9, 0.93, 0.97, 1))
		var toggle := CheckButton.new()
		toggle.text = "Bot"
		toggle.button_pressed = _bot_flags[i] if i > 0 else false
		if i == 0:
			toggle.button_pressed = false
			toggle.disabled = true
		var seat_i := i
		toggle.toggled.connect(func(on: bool) -> void: _bot_flags[seat_i] = on)
		row.add_child(swatch)
		row.add_child(label)
		row.add_child(toggle)
		card.add_child(row)
		_seats.add_child(card)


func _bot_mask() -> int:
	var mask := 0
	for i in _player_count:
		if i < _bot_flags.size() and _bot_flags[i]:
			mask |= 1 << i
	# Seat 0 always human.
	mask &= ~1
	return mask


func _on_start() -> void:
	var host := _find_host()
	if host != null and host.has_method("configure_match"):
		host.call("configure_match", _player_count, _bot_mask(), 1)
	_submit(SceneRequest.replace(PLAY_PATH))


func _on_quit() -> void:
	_submit(SceneRequest.quit())


func _find_host() -> Node:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("configure_match"):
			return node
		node = node.get_parent()
	return null


func _submit(req: SceneRequest) -> void:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("submit"):
			node.call("submit", req)
			return
		node = node.get_parent()
