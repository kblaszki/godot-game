extends Control

const SETUP_PATH := "res://games/districts/app/setup.tscn"
const PAUSE_PATH := "res://games/districts/app/pause_menu.tscn"
const BOARD_SIZE := Vector2(720, 520)
const TILE := Vector2(56, 40)

const PAWN_COLORS: Array[Color] = [
	Color(0.95, 0.45, 0.4, 1),
	Color(0.4, 0.75, 1.0, 1),
	Color(0.45, 0.9, 0.55, 1),
	Color(0.95, 0.8, 0.35, 1),
]
const GROUP_COLORS: Array[Color] = [
	Color(0.55, 0.35, 0.25, 1),
	Color(0.35, 0.55, 0.85, 1),
	Color(0.85, 0.45, 0.2, 1),
	Color(0.75, 0.3, 0.55, 1),
	Color(0.3, 0.7, 0.45, 1),
	Color(0.9, 0.75, 0.25, 1),
	Color(0.25, 0.35, 0.55, 1),
]

var _sim: DistrictSim
var _tile_nodes: Array[ColorRect] = []
var _pawn_nodes: Array[ColorRect] = []
var _tile_positions: Array[Vector2] = []
var _log_lines: PackedStringArray = PackedStringArray()
var _bot_cooldown: float = 0.0

@onready var _board: Node2D = $BoardRoot/Board
@onready var _pawns: Node2D = $BoardRoot/Pawns
@onready var _roster: VBoxContainer = $Hud/Roster
@onready var _log: Label = $Hud/Log
@onready var _turn: Label = $Hud/Turn
@onready var _roll: Button = $Hud/Actions/Roll
@onready var _buy: Button = $Hud/Actions/Buy
@onready var _skip: Button = $Hud/Actions/Skip
@onready var _banner: Label = $Hud/Banner


func _ready() -> void:
	var players := 2
	var bot_mask := 0
	var seed_value := 1
	var host := _find_host()
	if host != null:
		players = int(host.get("match_players"))
		bot_mask = int(host.get("match_bot_mask"))
		seed_value = int(host.get("match_seed"))
	_sim = DistrictSim.new(DistrictConfig.new(), SeededRng.new(seed_value))
	_sim.setup(players, bot_mask, seed_value)
	_roll.pressed.connect(_on_roll)
	_buy.pressed.connect(_on_buy)
	_skip.pressed.connect(_on_skip)
	_build_board()
	_build_pawns()
	_fit_board()
	_refresh()


func _process(delta: float) -> void:
	if _sim.get_phase() == DistrictSim.PHASE_OVER:
		return
	var player := _sim.get_player(_sim.get_current_player())
	if not player.is_bot or player.bankrupt:
		return
	_bot_cooldown -= delta
	if _bot_cooldown > 0.0:
		return
	_apply_events(_sim.bot_act())
	_bot_cooldown = 0.45


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_submit(SceneRequest.push(PAUSE_PATH))
		get_viewport().set_input_as_handled()
	elif _sim.get_phase() == DistrictSim.PHASE_OVER:
		if event.is_action_pressed("ui_accept"):
			_submit(SceneRequest.replace(SETUP_PATH))
			get_viewport().set_input_as_handled()


func _on_roll() -> void:
	if _sim.get_phase() != DistrictSim.PHASE_ROLL:
		return
	if _sim.get_player(_sim.get_current_player()).is_bot:
		return
	_apply_events(_sim.roll())


func _on_buy() -> void:
	if _sim.get_phase() != DistrictSim.PHASE_BUY:
		return
	if _sim.get_player(_sim.get_current_player()).is_bot:
		return
	_apply_events(_sim.buy())


func _on_skip() -> void:
	if _sim.get_phase() != DistrictSim.PHASE_BUY:
		return
	if _sim.get_player(_sim.get_current_player()).is_bot:
		return
	_apply_events(_sim.skip())


func _apply_events(events: Array) -> void:
	for item in events:
		var data := item as Dictionary
		_log_lines.append(_format_event(data))
	while _log_lines.size() > 8:
		_log_lines.remove_at(0)
	_refresh()


func _format_event(data: Dictionary) -> String:
	match str(data.get("type", "")):
		"rolled":
			return "P%d rolled %d+%d" % [int(data.get("player", 0)) + 1, int(data.get("d1", 0)), int(data.get("d2", 0))]
		"moved":
			return "P%d → %d" % [int(data.get("player", 0)) + 1, int(data.get("to", 0))]
		"bought":
			return "P%d bought #%d" % [int(data.get("player", 0)) + 1, int(data.get("space", 0))]
		"paid_rent":
			return "P%d paid %d rent" % [int(data.get("from", 0)) + 1, int(data.get("amount", 0))]
		"went_to_jail":
			return "P%d jailed" % [int(data.get("player", 0)) + 1]
		"bankrupt":
			return "P%d bankrupt" % [int(data.get("player", 0)) + 1]
		"game_over":
			return "Winner P%d" % [int(data.get("winner", 0)) + 1]
		"turn_changed":
			return "Turn P%d" % [int(data.get("player", 0)) + 1]
		_:
			return str(data.get("type", ""))


func _build_board() -> void:
	_tile_positions = _ring_positions(_sim.get_config().space_count())
	for i in _sim.get_config().space_count():
		var space := _sim.get_config().space_at(i)
		var tile := ColorRect.new()
		tile.size = TILE
		tile.position = _tile_positions[i]
		tile.color = _space_color(space)
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var label := Label.new()
		label.text = str(i)
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
		tile.add_child(label)
		_board.add_child(tile)
		_tile_nodes.append(tile)


func _build_pawns() -> void:
	for i in _sim.get_player_count():
		var pawn := ColorRect.new()
		pawn.size = Vector2(14, 14)
		pawn.color = PAWN_COLORS[i % PAWN_COLORS.size()]
		pawn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pawns.add_child(pawn)
		_pawn_nodes.append(pawn)


func _fit_board() -> void:
	var content := BOARD_SIZE
	var fit := ViewFit.compute(content, $BoardRoot.size if $BoardRoot.size.x > 1.0 else get_viewport_rect().size * Vector2(0.7, 0.9))
	# BoardRoot is full-rect; place board with margin.
	var origin := Vector2(24, 24)
	_board.position = origin
	_pawns.position = origin


func _ring_positions(count: int) -> Array[Vector2]:
	# Rectangular loop: bottom, left, top, right — isometric-ish offset for wave 4 polish later.
	var per_side := count / 4
	var positions: Array[Vector2] = []
	positions.resize(count)
	var idx := 0
	for i in per_side:
		positions[idx] = Vector2(float(i) * (TILE.x + 4.0), float(per_side) * (TILE.y + 4.0))
		idx += 1
	for i in per_side:
		positions[idx] = Vector2(float(per_side) * (TILE.x + 4.0), float(per_side - i) * (TILE.y + 4.0))
		idx += 1
	for i in per_side:
		positions[idx] = Vector2(float(per_side - i) * (TILE.x + 4.0), 0.0)
		idx += 1
	for i in per_side:
		positions[idx] = Vector2(0.0, float(i) * (TILE.y + 4.0))
		idx += 1
	# Leftover spaces if count % 4 != 0
	while idx < count:
		positions[idx] = Vector2(float(idx) * 8.0, float(per_side + 1) * (TILE.y + 4.0))
		idx += 1
	# Apply light iso skew
	for i in positions.size():
		var p := positions[i]
		positions[i] = Vector2(p.x - p.y * 0.35, p.x * 0.2 + p.y * 0.55) + Vector2(180, 40)
	return positions


func _space_color(space: BoardSpace) -> Color:
	match space.kind:
		BoardSpace.KIND_GO:
			return Color(0.25, 0.65, 0.45, 1)
		BoardSpace.KIND_JAIL:
			return Color(0.35, 0.35, 0.4, 1)
		BoardSpace.KIND_GOTO_JAIL:
			return Color(0.55, 0.2, 0.25, 1)
		BoardSpace.KIND_TAX:
			return Color(0.45, 0.35, 0.2, 1)
		BoardSpace.KIND_FREE:
			return Color(0.2, 0.45, 0.55, 1)
		BoardSpace.KIND_PROPERTY:
			if space.group >= 0 and space.group < GROUP_COLORS.size():
				return GROUP_COLORS[space.group]
	return Color(0.25, 0.28, 0.35, 1)


func _refresh() -> void:
	for i in _tile_nodes.size():
		var owner := _sim.get_owner(i)
		var base := _space_color(_sim.get_config().space_at(i))
		if owner >= 0:
			_tile_nodes[i].color = base.lightened(0.15).lerp(PAWN_COLORS[owner % PAWN_COLORS.size()], 0.35)
		else:
			_tile_nodes[i].color = base
		_tile_nodes[i].modulate = Color(1, 1, 1, 1)
	var current := _sim.get_current_player()
	if current >= 0 and current < _tile_nodes.size():
		var pos := _sim.get_player(current).position
		if pos >= 0 and pos < _tile_nodes.size():
			_tile_nodes[pos].modulate = Color(1.25, 1.25, 1.1, 1)

	for i in _pawn_nodes.size():
		var player := _sim.get_player(i)
		_pawn_nodes[i].visible = not player.bankrupt
		var tile_pos := _tile_positions[player.position]
		_pawn_nodes[i].position = tile_pos + Vector2(6 + i * 10, 12 + (i % 2) * 10)

	for child in _roster.get_children():
		child.queue_free()
	for i in _sim.get_player_count():
		var player := _sim.get_player(i)
		var row := Label.new()
		var mark := "●" if i == _sim.get_current_player() else "○"
		var bot := " bot" if player.is_bot else ""
		var jail := " [jail]" if player.in_jail else ""
		var dead := " OUT" if player.bankrupt else ""
		row.text = "%s P%d%s  $%d  props:%d%s%s" % [mark, i + 1, bot, player.cash, player.owned.size(), jail, dead]
		row.add_theme_color_override("font_color", PAWN_COLORS[i % PAWN_COLORS.size()])
		_roster.add_child(row)

	_log.text = "\n".join(_log_lines)
	var phase := _sim.get_phase()
	_turn.text = "Turn P%d · %s" % [_sim.get_current_player() + 1, phase]
	var human := not _sim.get_player(_sim.get_current_player()).is_bot
	_roll.disabled = not (phase == DistrictSim.PHASE_ROLL and human)
	_buy.disabled = not (phase == DistrictSim.PHASE_BUY and human)
	_skip.disabled = not (phase == DistrictSim.PHASE_BUY and human)
	if phase == DistrictSim.PHASE_OVER:
		_banner.visible = true
		_banner.text = "P%d wins the districts\nEnter — setup" % [_sim.get_winner() + 1]
		_roll.disabled = true
		_buy.disabled = true
		_skip.disabled = true
	else:
		_banner.visible = false


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
