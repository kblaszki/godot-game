extends Control

const PLAY_PATH := "res://games/minigolf/app/play.tscn"
const MENU_PATH := "res://games/minigolf/app/menu.tscn"

var _player_count: int = 2
var _bot_flags: Array[bool] = [false, true, true, true]

@onready var _count_label: Label = $Center/Panel/Margin/Column/CountRow/Count
@onready var _minus: Button = $Center/Panel/Margin/Column/CountRow/Minus
@onready var _plus: Button = $Center/Panel/Margin/Column/CountRow/Plus
@onready var _seats: VBoxContainer = $Center/Panel/Margin/Column/Seats
@onready var _start: Button = $Center/Panel/Margin/Column/Start
@onready var _back: Button = $Center/Panel/Margin/Column/Back


func _ready() -> void:
	_minus.pressed.connect(func() -> void:
		_player_count = maxi(1, _player_count - 1)
		_rebuild()
	)
	_plus.pressed.connect(func() -> void:
		_player_count = mini(4, _player_count + 1)
		_rebuild()
	)
	_start.pressed.connect(_on_start)
	_back.pressed.connect(func() -> void: _submit(SceneRequest.replace(MENU_PATH)))
	_rebuild()
	_start.grab_focus()


func _rebuild() -> void:
	_count_label.text = str(_player_count)
	for child in _seats.get_children():
		child.queue_free()
	for i in _player_count:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = "P%d" % (i + 1)
		label.custom_minimum_size = Vector2(48, 0)
		var toggle := CheckButton.new()
		toggle.text = "Bot"
		toggle.button_pressed = i > 0 and i < _bot_flags.size() and _bot_flags[i]
		if i == 0:
			toggle.button_pressed = false
			toggle.disabled = true
		var seat_i := i
		toggle.toggled.connect(func(on: bool) -> void:
			if seat_i < _bot_flags.size():
				_bot_flags[seat_i] = on
		)
		row.add_child(label)
		row.add_child(toggle)
		_seats.add_child(row)


func _bot_mask() -> int:
	var mask := 0
	for i in _player_count:
		if i == 0:
			continue
		if i < _bot_flags.size() and _bot_flags[i]:
			mask |= 1 << i
	return mask


func _on_start() -> void:
	var host := _find_host()
	if host != null and host.has_method("configure_match"):
		host.call("configure_match", _player_count, _bot_mask(), 1)
	_submit(SceneRequest.replace(PLAY_PATH))


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
