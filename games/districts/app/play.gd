extends Control

const SETUP_PATH := "res://games/districts/app/setup.tscn"
const PAUSE_PATH := "res://games/districts/app/pause_menu.tscn"

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
var _tile_polys: Array[Polygon2D] = []
var _tile_labels: Array[Label] = []
var _pawn_nodes: Array[Polygon2D] = []
var _tile_centers: Array[Vector2] = []
var _log_lines: PackedStringArray = PackedStringArray()
var _bot_cooldown: float = 0.0
var _pulse: float = 0.0

@onready var _board: Node2D = $BoardRoot/Board
@onready var _pawns: Node2D = $BoardRoot/Pawns
@onready var _roster: VBoxContainer = $Hud/Roster
@onready var _log: Label = $Hud/Log
@onready var _turn: Label = $Hud/Turn
@onready var _offer: Label = $Hud/Offer
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
	_refresh()


func _process(delta: float) -> void:
	_pulse += delta
	_highlight_current_tile()
	if _sim.get_phase() == DistrictSim.PHASE_OVER:
		return
	var player := _sim.get_player(_sim.get_current_player())
	if not player.is_bot or player.bankrupt:
		return
	_bot_cooldown -= delta
	if _bot_cooldown > 0.0:
		return
	_apply_events(_sim.bot_act())
	_bot_cooldown = 0.4


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
		_log_lines.append(_format_event(item as Dictionary))
	while _log_lines.size() > 10:
		_log_lines.remove_at(0)
	_refresh()


func _format_event(data: Dictionary) -> String:
	match str(data.get("type", "")):
		"rolled":
			return "P%d  %d+%d=%d" % [
				int(data.get("player", 0)) + 1,
				int(data.get("d1", 0)),
				int(data.get("d2", 0)),
				int(data.get("total", 0)),
			]
		"moved":
			var space := _sim.get_config().space_at(int(data.get("to", 0)))
			return "P%d → %s" % [int(data.get("player", 0)) + 1, space.name]
		"bought":
			return "P%d bought %s" % [
				int(data.get("player", 0)) + 1,
				_sim.get_config().space_at(int(data.get("space", 0))).name,
			]
		"paid_rent":
			return "Rent %d: P%d→P%d" % [
				int(data.get("amount", 0)),
				int(data.get("from", 0)) + 1,
				int(data.get("to", 0)) + 1,
			]
		"taxed":
			return "Tax %d on P%d" % [int(data.get("amount", 0)), int(data.get("player", 0)) + 1]
		"went_to_jail":
			return "P%d → Holding" % [int(data.get("player", 0)) + 1]
		"left_jail":
			return "P%d left Holding" % [int(data.get("player", 0)) + 1]
		"bankrupt":
			return "P%d bankrupt" % [int(data.get("player", 0)) + 1]
		"game_over":
			return "Winner: P%d" % [int(data.get("winner", 0)) + 1]
		"turn_changed":
			return "— Turn P%d —" % [int(data.get("player", 0)) + 1]
		"offer_buy":
			return "Offer: %s ($%d)" % [
				_sim.get_config().space_at(int(data.get("space", 0))).name,
				int(data.get("price", 0)),
			]
		"passed_go":
			return "P%d +$%d Plaza" % [int(data.get("player", 0)) + 1, int(data.get("amount", 0))]
		_:
			return str(data.get("type", ""))


func _build_board() -> void:
	_tile_centers = _iso_ring_centers(_sim.get_config().space_count())
	# Soft ground diamond under the ring.
	var ground := Polygon2D.new()
	ground.polygon = PackedVector2Array([
		Vector2(420, 40), Vector2(780, 280), Vector2(420, 520), Vector2(60, 280),
	])
	ground.color = Color(0.12, 0.16, 0.2, 0.9)
	_board.add_child(ground)
	for i in _sim.get_config().space_count():
		var space := _sim.get_config().space_at(i)
		var center := _tile_centers[i]
		var poly := Polygon2D.new()
		poly.polygon = _iso_diamond(28.0, 16.0)
		poly.position = center
		poly.color = _space_color(space)
		_board.add_child(poly)
		_tile_polys.append(poly)
		var label := Label.new()
		label.text = space.name.substr(0, 10)
		label.position = center + Vector2(-28, -8)
		label.add_theme_font_size_override("font_size", 9)
		label.add_theme_color_override("font_color", Color(1, 1, 1, 0.92))
		_board.add_child(label)
		_tile_labels.append(label)


func _build_pawns() -> void:
	for i in _sim.get_player_count():
		var pawn := Polygon2D.new()
		pawn.polygon = PackedVector2Array([
			Vector2(0, -10), Vector2(8, 4), Vector2(0, 8), Vector2(-8, 4),
		])
		pawn.color = PAWN_COLORS[i % PAWN_COLORS.size()]
		_pawns.add_child(pawn)
		_pawn_nodes.append(pawn)


func _iso_ring_centers(count: int) -> Array[Vector2]:
	var per_side := count / 4
	var grid: Array[Vector2] = []
	grid.resize(count)
	var idx := 0
	for i in per_side:
		grid[idx] = Vector2(float(i), float(per_side))
		idx += 1
	for i in per_side:
		grid[idx] = Vector2(float(per_side), float(per_side - i))
		idx += 1
	for i in per_side:
		grid[idx] = Vector2(float(per_side - i), 0.0)
		idx += 1
	for i in per_side:
		grid[idx] = Vector2(0.0, float(i))
		idx += 1
	while idx < count:
		grid[idx] = Vector2(float(idx % (per_side + 1)), float(per_side + 1))
		idx += 1
	var centers: Array[Vector2] = []
	for g in grid:
		centers.append(_grid_to_iso(g) + Vector2(120, 70))
	return centers


func _grid_to_iso(g: Vector2) -> Vector2:
	var tile_w := 54.0
	var tile_h := 30.0
	return Vector2((g.x - g.y) * tile_w * 0.5, (g.x + g.y) * tile_h * 0.5)


func _iso_diamond(half_w: float, half_h: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0, -half_h),
		Vector2(half_w, 0),
		Vector2(0, half_h),
		Vector2(-half_w, 0),
	])


func _space_color(space: BoardSpace) -> Color:
	match space.kind:
		BoardSpace.KIND_GO:
			return Color(0.25, 0.7, 0.5, 1)
		BoardSpace.KIND_JAIL:
			return Color(0.4, 0.4, 0.48, 1)
		BoardSpace.KIND_GOTO_JAIL:
			return Color(0.65, 0.22, 0.28, 1)
		BoardSpace.KIND_TAX:
			return Color(0.55, 0.42, 0.22, 1)
		BoardSpace.KIND_FREE:
			return Color(0.22, 0.5, 0.62, 1)
		BoardSpace.KIND_PROPERTY:
			if space.group >= 0 and space.group < GROUP_COLORS.size():
				return GROUP_COLORS[space.group]
	return Color(0.28, 0.32, 0.4, 1)


func _highlight_current_tile() -> void:
	if _tile_polys.is_empty():
		return
	for poly in _tile_polys:
		poly.scale = Vector2.ONE
	var player := _sim.get_player(_sim.get_current_player())
	if player.position >= 0 and player.position < _tile_polys.size():
		var s := 1.0 + 0.06 * (0.5 + 0.5 * sin(_pulse * 4.0))
		_tile_polys[player.position].scale = Vector2(s, s)


func _refresh() -> void:
	for i in _tile_polys.size():
		var owner := _sim.get_owner(i)
		var base := _space_color(_sim.get_config().space_at(i))
		if owner >= 0:
			_tile_polys[i].color = base.lerp(PAWN_COLORS[owner % PAWN_COLORS.size()], 0.4)
		else:
			_tile_polys[i].color = base

	for i in _pawn_nodes.size():
		var player := _sim.get_player(i)
		_pawn_nodes[i].visible = not player.bankrupt
		var center := _tile_centers[player.position]
		_pawn_nodes[i].position = center + Vector2(float(i) * 7.0 - 10.0, -18.0 - float(i % 2) * 6.0)

	for child in _roster.get_children():
		child.queue_free()
	for i in _sim.get_player_count():
		var player := _sim.get_player(i)
		var row := Label.new()
		var mark := "▶" if i == _sim.get_current_player() else "·"
		var bot := " BOT" if player.is_bot else ""
		var jail := " jail" if player.in_jail else ""
		var dead := " OUT" if player.bankrupt else ""
		row.text = "%s P%d%s  $%d  x%d%s%s" % [
			mark, i + 1, bot, player.cash, player.owned.size(), jail, dead,
		]
		row.add_theme_color_override("font_color", PAWN_COLORS[i % PAWN_COLORS.size()])
		_roster.add_child(row)

	_log.text = "\n".join(_log_lines)
	var phase := _sim.get_phase()
	_turn.text = "Seat %d · %s" % [_sim.get_current_player() + 1, phase.to_upper()]
	if phase == DistrictSim.PHASE_BUY and _sim.get_pending_space() >= 0:
		var space := _sim.get_config().space_at(_sim.get_pending_space())
		_offer.text = "Buy %s for $%d?" % [space.name, space.price]
		_offer.visible = true
	else:
		_offer.visible = false

	var human := not _sim.get_player(_sim.get_current_player()).is_bot
	_roll.disabled = not (phase == DistrictSim.PHASE_ROLL and human)
	_buy.disabled = not (phase == DistrictSim.PHASE_BUY and human)
	_skip.disabled = not (phase == DistrictSim.PHASE_BUY and human)
	if phase == DistrictSim.PHASE_OVER:
		_banner.visible = true
		_banner.text = "P%d holds the districts\nEnter — new match" % [_sim.get_winner() + 1]
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
