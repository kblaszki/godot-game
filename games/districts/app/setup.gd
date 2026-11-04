extends Control

const PLAY_PATH := "res://games/districts/app/play.tscn"

var _player_count: int = 2
var _bot_flags: Array[bool] = [false, true, true, true]

@onready var _count_label: Label = $Center/Panel/Column/CountRow/Count
@onready var _seats: VBoxContainer = $Center/Panel/Column/Seats
@onready var _start: Button = $Center/Panel/Column/Start
@onready var _quit: Button = $Center/Panel/Column/Quit


func _ready() -> void:
	$Center/Panel/Column/CountRow/Minus.pressed.connect(_on_minus)
	$Center/Panel/Column/CountRow/Plus.pressed.connect(_on_plus)
	_start.pressed.connect(_on_start)
	_quit.pressed.connect(_on_quit)
	_rebuild_seats()
	_start.grab_focus()


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
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = "Seat %d" % (i + 1)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var toggle := CheckButton.new()
		toggle.text = "Bot"
		toggle.button_pressed = _bot_flags[i] if i > 0 else false
		if i == 0:
			toggle.button_pressed = false
			toggle.disabled = true
		var seat_i := i
		toggle.toggled.connect(func(on: bool) -> void: _bot_flags[seat_i] = on)
		row.add_child(label)
		row.add_child(toggle)
		_seats.add_child(row)


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
