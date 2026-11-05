extends Control

const SETUP_PATH := "res://games/districts/app/setup.tscn"
const PAUSE_PATH := "res://games/districts/app/pause_menu.tscn"
const ZOOM_MIN := 0.35
const ZOOM_MAX := 2.4
const PAD := 48.0

const MEEPLE_PATHS: Array[String] = [
	"res://games/districts/assets/kenney_boardgame/pieces/meeple_red.png",
	"res://games/districts/assets/kenney_boardgame/pieces/meeple_blue.png",
	"res://games/districts/assets/kenney_boardgame/pieces/meeple_green.png",
	"res://games/districts/assets/kenney_boardgame/pieces/meeple_yellow.png",
]
const PAWN_COLORS: Array[Color] = [
	Color(0.95, 0.45, 0.4, 1),
	Color(0.4, 0.75, 1.0, 1),
	Color(0.45, 0.9, 0.55, 1),
	Color(0.95, 0.8, 0.35, 1),
]

var _sim: DistrictSim
var _tile_sprites: Array[Sprite2D] = []
var _pawn_nodes: Array[Sprite2D] = []
var _tile_centers: Array[Vector2] = []
var _board_rect: Rect2 = Rect2()
var _log_lines: PackedStringArray = PackedStringArray()
var _bot_cooldown: float = 0.0
var _pulse: float = 0.0
var _dragging: bool = false
var _drag_last: Vector2 = Vector2.ZERO
var _follow_t: float = 0.0
var _follow_target: Vector2 = Vector2.ZERO
var _dice_timer: float = 0.0

@onready var _board_root: Control = $BoardRoot
@onready var _felt: TextureRect = $BoardRoot/Felt
@onready var _svc: SubViewportContainer = $BoardRoot/SubViewportContainer
@onready var _board: Node2D = $BoardRoot/SubViewportContainer/SubViewport/World/Board
@onready var _pawns: Node2D = $BoardRoot/SubViewportContainer/SubViewport/World/Pawns
@onready var _camera: Camera2D = $BoardRoot/SubViewportContainer/SubViewport/Camera2D
@onready var _dice_overlay: HBoxContainer = $BoardRoot/DiceOverlay
@onready var _die_a: TextureRect = $BoardRoot/DiceOverlay/DieA
@onready var _die_b: TextureRect = $BoardRoot/DiceOverlay/DieB
@onready var _roster: VBoxContainer = $Hud/Roster
@onready var _log: Label = $Hud/Log
@onready var _turn: Label = $Hud/Turn
@onready var _offer: Label = $Hud/Offer
@onready var _fit_btn: Button = $Hud/Actions/Fit
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
	_felt.texture = load("res://games/districts/assets/tiles/felt.png")
	_felt.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_roll.pressed.connect(_on_roll)
	_buy.pressed.connect(_on_buy)
	_skip.pressed.connect(_on_skip)
	_fit_btn.pressed.connect(_fit_camera)
	_board_root.resized.connect(_on_board_resized)
	_svc.gui_input.connect(_on_board_gui_input)
	_build_board()
	_build_pawns()
	_camera.make_current()
	await get_tree().process_frame
	_fit_camera()
	_refresh()


func _process(delta: float) -> void:
	_pulse += delta
	_highlight_current_tile()
	if _dice_timer > 0.0:
		_dice_timer -= delta
		if _dice_timer <= 0.0:
			_dice_overlay.visible = false
	if _follow_t > 0.0:
		_follow_t = maxf(0.0, _follow_t - delta)
		_camera.position = _camera.position.lerp(_follow_target, 1.0 - exp(-6.0 * delta))
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


func _on_board_resized() -> void:
	_fit_camera()


func _view_size() -> Vector2:
	var sz := _svc.size
	if sz.x < 2.0 or sz.y < 2.0:
		return Vector2(800, 600)
	return sz


func _on_board_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = mb.pressed
			_drag_last = mb.position
			_follow_t = 0.0
			_svc.accept_event()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at(mb.position, 1.12)
			_svc.accept_event()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at(mb.position, 1.0 / 1.12)
			_svc.accept_event()
	elif event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		var delta := mm.position - _drag_last
		_drag_last = mm.position
		_camera.position -= delta / _camera.zoom
		_svc.accept_event()


func _zoom_at(screen_pos: Vector2, factor: float) -> void:
	var before := _camera.get_screen_center_position()
	# Convert container-local to world roughly via camera.
	var old_zoom := _camera.zoom.x
	var new_zoom := clampf(old_zoom * factor, ZOOM_MIN, ZOOM_MAX)
	if is_equal_approx(new_zoom, old_zoom):
		return
	var local := screen_pos - _svc.size * 0.5
	var world_under := _camera.position + local / old_zoom
	_camera.zoom = Vector2(new_zoom, new_zoom)
	_camera.position = world_under - local / new_zoom
	_follow_t = 0.0
	# Keep roughly centered feel if needed
	if before == Vector2.ZERO:
		pass


func _fit_camera() -> void:
	if _board_rect.size.x <= 1.0:
		return
	var view := _view_size()
	var target := _board_rect.grow(PAD)
	var zoom_x := view.x / maxf(target.size.x, 1.0)
	var zoom_y := view.y / maxf(target.size.y, 1.0)
	var z := clampf(minf(zoom_x, zoom_y), ZOOM_MIN, ZOOM_MAX)
	_camera.zoom = Vector2(z, z)
	_camera.position = target.get_center()
	_follow_t = 0.0


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
		match str(data.get("type", "")):
			"rolled":
				_show_dice(int(data.get("d1", 1)), int(data.get("d2", 1)))
			"moved":
				var pid := int(data.get("player", 0))
				if pid >= 0 and pid < _sim.get_player_count():
					var pos := _sim.get_player(pid).position
					if pos >= 0 and pos < _tile_centers.size():
						_follow_target = _tile_centers[pos]
						_follow_t = 0.55
	while _log_lines.size() > 10:
		_log_lines.remove_at(0)
	_refresh()


func _show_dice(d1: int, d2: int) -> void:
	_die_a.texture = load("res://games/districts/assets/kenney_boardgame/dice/die_%d.png" % clampi(d1, 1, 6))
	_die_b.texture = load("res://games/districts/assets/kenney_boardgame/dice/die_%d.png" % clampi(d2, 1, 6))
	_dice_overlay.visible = true
	_dice_timer = 1.1


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
	for child in _board.get_children():
		child.queue_free()
	_tile_sprites.clear()
	_tile_centers = _iso_ring_centers(_sim.get_config().space_count())
	var min_p := Vector2(INF, INF)
	var max_p := Vector2(-INF, -INF)
	for i in _sim.get_config().space_count():
		var space := _sim.get_config().space_at(i)
		var center := _tile_centers[i]
		var sprite := Sprite2D.new()
		sprite.texture = _tile_texture(space)
		sprite.centered = true
		sprite.position = center
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_board.add_child(sprite)
		_tile_sprites.append(sprite)
		var half := Vector2(48, 28)
		min_p = min_p.min(center - half)
		max_p = max_p.max(center + half)
	_board_rect = Rect2(min_p, max_p - min_p)


func _build_pawns() -> void:
	for child in _pawns.get_children():
		child.queue_free()
	_pawn_nodes.clear()
	for i in _sim.get_player_count():
		var sprite := Sprite2D.new()
		sprite.texture = load(MEEPLE_PATHS[i % MEEPLE_PATHS.size()])
		sprite.centered = true
		sprite.scale = Vector2(0.55, 0.55)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.z_index = 10
		_pawns.add_child(sprite)
		_pawn_nodes.append(sprite)


func _tile_texture(space: BoardSpace) -> Texture2D:
	match space.kind:
		BoardSpace.KIND_GO:
			return load("res://games/districts/assets/tiles/go.png")
		BoardSpace.KIND_JAIL:
			return load("res://games/districts/assets/tiles/jail.png")
		BoardSpace.KIND_GOTO_JAIL:
			return load("res://games/districts/assets/tiles/goto_jail.png")
		BoardSpace.KIND_TAX:
			return load("res://games/districts/assets/tiles/tax.png")
		BoardSpace.KIND_FREE:
			return load("res://games/districts/assets/tiles/free.png")
		BoardSpace.KIND_PROPERTY:
			var g := clampi(space.group, 0, 6)
			return load("res://games/districts/assets/tiles/property_%d.png" % g)
	return load("res://games/districts/assets/tiles/free.png")


func _iso_ring_centers(count: int) -> Array[Vector2]:
	var per_side := maxi(count / 4, 1)
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
		grid[idx] = Vector2(float(idx % (per_side + 1)), float(per_side) + 1.0)
		idx += 1
	var centers: Array[Vector2] = []
	for g in grid:
		centers.append(_grid_to_iso(g))
	return centers


func _grid_to_iso(g: Vector2) -> Vector2:
	var tile_w := 86.0
	var tile_h := 48.0
	return Vector2((g.x - g.y) * tile_w * 0.5, (g.x + g.y) * tile_h * 0.5)


func _highlight_current_tile() -> void:
	if _tile_sprites.is_empty():
		return
	for sprite in _tile_sprites:
		sprite.scale = Vector2.ONE
		sprite.modulate = Color.WHITE
	var player := _sim.get_player(_sim.get_current_player())
	if player.position >= 0 and player.position < _tile_sprites.size():
		var s := 1.0 + 0.08 * (0.5 + 0.5 * sin(_pulse * 4.0))
		_tile_sprites[player.position].scale = Vector2(s, s)
		_tile_sprites[player.position].modulate = Color(1.15, 1.15, 1.05, 1)


func _refresh() -> void:
	for i in _tile_sprites.size():
		var owner := _sim.get_owner(i)
		if owner >= 0:
			_tile_sprites[i].modulate = Color.WHITE.lerp(PAWN_COLORS[owner % PAWN_COLORS.size()], 0.25)
		else:
			_tile_sprites[i].modulate = Color.WHITE

	for i in _pawn_nodes.size():
		var player := _sim.get_player(i)
		_pawn_nodes[i].visible = not player.bankrupt
		var center := _tile_centers[player.position]
		_pawn_nodes[i].position = center + Vector2(float(i) * 10.0 - 14.0, -22.0 - float(i % 2) * 8.0)

	for child in _roster.get_children():
		child.queue_free()
	for i in _sim.get_player_count():
		var player := _sim.get_player(i)
		var row := Label.new()
		var mark := ">" if i == _sim.get_current_player() else "-"
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
