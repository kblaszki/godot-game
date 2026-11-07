extends Control

const MENU_PATH := "res://games/minigolf/app/menu.tscn"

@onready var _title: Label = $Center/Column/Title
@onready var _body: Label = $Center/Column/Body
@onready var _again: Button = $Center/Column/Again


func _ready() -> void:
	var host := _find_host()
	var lines: PackedStringArray = PackedStringArray()
	if host != null and host.has_meta("match_rankings"):
		var rankings: PackedInt32Array = host.get_meta("match_rankings")
		var totals: PackedInt32Array = host.get_meta("match_totals") if host.has_meta("match_totals") else PackedInt32Array()
		if rankings.size() > 0:
			_title.text = "Winner: P%d" % (int(rankings[0]) + 1)
		for i in rankings.size():
			var seat := int(rankings[i])
			var total := int(totals[seat]) if seat < totals.size() else 0
			lines.append("%d. P%d — %d strokes" % [i + 1, seat + 1, total])
	else:
		_title.text = "Round over"
		lines.append("No scorecard data.")
	_body.text = "\n".join(lines)
	_again.pressed.connect(func() -> void: _submit(SceneRequest.replace(MENU_PATH)))
	_again.grab_focus()


func _find_host() -> Node:
	var node: Node = get_parent()
	while node != null:
		if "match_players" in node:
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
