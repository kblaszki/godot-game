extends Control

const SETUP_PATH := "res://games/districts/app/setup.tscn"
const PAUSE_PATH := "res://games/districts/app/pause_menu.tscn"
const ZOOM_MIN := 0.35
const ZOOM_MAX := 2.4
const PAD := 96.0
const STEP_SEC := 0.22
const EDGE_W := 80.0
const EDGE_H := 112.0
const CORNER := 112.0
const TILE_HALF := Vector2(64.0, 64.0)
const FOLLOW_POS_RATE := 1.7
const FOLLOW_ROT_RATE := 1.5
const ORBIT_SENS := 0.012
## How far the camera leans from board center toward the active space (0–1).
const FOLLOW_LEAN := 0.32
## Diamond presentation: square track rotated so a corner points down.
const REST_PIVOT_ROT := -PI * 0.25

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
var _panning: bool = false
var _orbiting: bool = false
var _drag_last: Vector2 = Vector2.ZERO
var _follow_t: float = 0.0
var _follow_target: Vector2 = Vector2.ZERO
var _follow_rot_target: float = 0.0
var _auto_orient: bool = true
var _busy: bool = false
var _cash_cache: Array[int] = []
var _banner_shown: bool = false
var _owner_pips: Array[Polygon2D] = []
var _follow_space_index: int = -1

@onready var _board_root: Control = $BoardRoot
@onready var _felt: TextureRect = $BoardRoot/Felt
@onready var _svc: SubViewportContainer = $BoardRoot/SubViewportContainer
@onready var _pivot: Node2D = $BoardRoot/SubViewportContainer/SubViewport/World/BoardPivot
@onready var _table_felt: Sprite2D = $BoardRoot/SubViewportContainer/SubViewport/World/BoardPivot/TableFelt
@onready var _table_plate: Polygon2D = $BoardRoot/SubViewportContainer/SubViewport/World/BoardPivot/TablePlate
@onready var _board: Node2D = $BoardRoot/SubViewportContainer/SubViewport/World/BoardPivot/Board
@onready var _fx: Node2D = $BoardRoot/SubViewportContainer/SubViewport/World/BoardPivot/Fx
@onready var _pawns: Node2D = $BoardRoot/SubViewportContainer/SubViewport/World/BoardPivot/Pawns
@onready var _camera: Camera2D = $BoardRoot/SubViewportContainer/SubViewport/Camera2D
@onready var _space_chip: PanelContainer = $BoardRoot/SpaceChip
@onready var _space_chip_label: Label = $BoardRoot/SpaceChip/SpaceChipLabel
@onready var _dice_overlay: HBoxContainer = $BoardRoot/DiceOverlay
@onready var _die_a: TextureRect = $BoardRoot/DiceOverlay/DieA
@onready var _die_b: TextureRect = $BoardRoot/DiceOverlay/DieB
@onready var _toast_layer: Control = $BoardRoot/ToastLayer
@onready var _hud_panel: PanelContainer = $Hud/Panel
@onready var _roster: VBoxContainer = $Hud/Panel/Margin/Column/Roster
@onready var _log: RichTextLabel = $Hud/Panel/Margin/Column/Log
@onready var _turn: Label = $Hud/Panel/Margin/Column/Header/Turn
@onready var _offer: Label = $Hud/Panel/Margin/Column/Header/Offer
@onready var _fit_btn: Button = $Hud/Panel/Margin/Column/Actions/Fit
@onready var _roll: Button = $Hud/Panel/Margin/Column/Actions/Roll
@onready var _buy: Button = $Hud/Panel/Margin/Column/Actions/BuyRow/Buy
@onready var _skip: Button = $Hud/Panel/Margin/Column/Actions/BuyRow/Skip
@onready var _banner: PanelContainer = $Banner
@onready var _banner_label: Label = $Banner/BannerLabel


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
	_cash_cache.clear()
	for i in _sim.get_player_count():
		_cash_cache.append(_sim.get_player(i).cash)
	_felt.texture = load("res://games/districts/assets/tiles/felt.png")
	_felt.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_apply_styles()
	_roll.pressed.connect(_on_roll)
	_buy.pressed.connect(_on_buy)
	_skip.pressed.connect(_on_skip)
	_fit_btn.pressed.connect(_fit_camera)
	_board_root.resized.connect(_fit_camera)
	_svc.gui_input.connect(_on_board_gui_input)
	_build_board()
	_build_pawns()
	_camera.make_current()
	await get_tree().process_frame
	_fit_camera()
	_refresh_hud()
	_push_log("[color=#7dcea0]Table set. Claim the ring.[/color]")


func _apply_styles() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.08, 0.1, 0.14, 0.96)
	panel.set_border_width_all(1)
	panel.border_color = Color(1, 1, 1, 0.08)
	panel.set_corner_radius_all(14)
	panel.content_margin_left = 0
	panel.content_margin_right = 0
	_hud_panel.add_theme_stylebox_override("panel", panel)

	var chip := StyleBoxFlat.new()
	chip.bg_color = Color(0.06, 0.09, 0.12, 0.88)
	chip.set_border_width_all(1)
	chip.border_color = Color(0.35, 0.85, 0.65, 0.55)
	chip.set_corner_radius_all(10)
	chip.content_margin_left = 12
	chip.content_margin_right = 12
	chip.content_margin_top = 6
	chip.content_margin_bottom = 6
	_space_chip.add_theme_stylebox_override("panel", chip)

	var banner := StyleBoxFlat.new()
	banner.bg_color = Color(0.07, 0.09, 0.12, 0.94)
	banner.set_border_width_all(2)
	banner.border_color = Color(1.0, 0.82, 0.35, 0.85)
	banner.set_corner_radius_all(16)
	banner.content_margin_left = 20
	banner.content_margin_right = 20
	banner.content_margin_top = 16
	banner.content_margin_bottom = 16
	_banner.add_theme_stylebox_override("panel", banner)

	_style_button(_fit_btn, Color(0.18, 0.22, 0.28, 1), false)
	_style_button(_roll, Color(0.18, 0.55, 0.42, 1), true)
	_style_button(_buy, Color(0.55, 0.42, 0.15, 1), true)
	_style_button(_skip, Color(0.22, 0.25, 0.32, 1), false)


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


func _process(delta: float) -> void:
	_pulse += delta
	_highlight_current_tile()
	_update_camera(delta)
	if _busy or _sim.get_phase() == DistrictSim.PHASE_OVER:
		return
	var player := _sim.get_player(_sim.get_current_player())
	if not player.is_bot or player.bankrupt:
		return
	_bot_cooldown -= delta
	if _bot_cooldown > 0.0:
		return
	_bot_cooldown = 0.55
	_run_action(func() -> Array: return _sim.bot_act())


func _follow_space_valid() -> bool:
	return _follow_space_index >= 0 and _follow_space_index < _tile_centers.size()


func _board_center() -> Vector2:
	return _pivot.position


func _framing_target() -> Vector2:
	## Mostly stay on the table center; lean slightly toward the active space.
	if not _follow_space_valid():
		return _board_center()
	return _board_center().lerp(_tile_world_pos(_follow_space_index), FOLLOW_LEAN)


func _update_camera(delta: float) -> void:
	if _orbiting or _panning:
		return
	if _follow_t <= 0.0 and not (_auto_orient and _busy and _follow_space_valid()):
		return
	if _follow_t > 0.0:
		_follow_t = maxf(0.0, _follow_t - delta)
	_follow_target = _framing_target()
	var pos_t := 1.0 - exp(-FOLLOW_POS_RATE * delta)
	_camera.position = _camera.position.lerp(_follow_target, pos_t)
	if _auto_orient:
		var rot_t := 1.0 - exp(-FOLLOW_ROT_RATE * delta)
		_pivot.rotation = lerp_angle(_pivot.rotation, _follow_rot_target, rot_t)
		# Recompute lean after the table turns so framing stays stable.
		_follow_target = _framing_target()
		_camera.position = _camera.position.lerp(_follow_target, pos_t)


func _unhandled_input(event: InputEvent) -> void:
	if _busy:
		return
	if event.is_action_pressed("ui_cancel"):
		_submit(SceneRequest.push(PAUSE_PATH))
		get_viewport().set_input_as_handled()
	elif _sim.get_phase() == DistrictSim.PHASE_OVER:
		if event.is_action_pressed("ui_accept"):
			_submit(SceneRequest.replace(SETUP_PATH))
			get_viewport().set_input_as_handled()


func _on_board_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_orbiting = mb.pressed
			_panning = false
			_drag_last = mb.position
			if mb.pressed:
				_follow_t = 0.0
				_auto_orient = false
			else:
				# After orbit, ease camera back to table center.
				_follow_space_index = -1
				_follow_target = _board_center()
				_follow_t = 0.6
			_svc.accept_event()
		elif mb.button_index == MOUSE_BUTTON_MIDDLE or mb.button_index == MOUSE_BUTTON_RIGHT:
			_panning = mb.pressed
			_orbiting = false
			_drag_last = mb.position
			if mb.pressed:
				_follow_t = 0.0
				_auto_orient = false
			_svc.accept_event()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at(mb.position, 1.1)
			_svc.accept_event()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at(mb.position, 1.0 / 1.1)
			_svc.accept_event()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var delta := mm.position - _drag_last
		_drag_last = mm.position
		if _orbiting:
			# Spin the table in place; keep the camera on the board center.
			_pivot.rotation += delta.x * ORBIT_SENS
			_camera.position = _board_center()
			_svc.accept_event()
		elif _panning:
			_camera.position -= delta / _camera.zoom.x
			_svc.accept_event()


func _zoom_at(screen_pos: Vector2, factor: float) -> void:
	var old_zoom := _camera.zoom.x
	var new_zoom := clampf(old_zoom * factor, ZOOM_MIN, ZOOM_MAX)
	if is_equal_approx(new_zoom, old_zoom):
		return
	var local := screen_pos - _svc.size * 0.5
	var world_under := _camera.position + local / old_zoom
	_camera.zoom = Vector2(new_zoom, new_zoom)
	_camera.position = world_under - local / new_zoom
	_follow_t = 0.0
	_auto_orient = false


func _view_size() -> Vector2:
	var sz := _svc.size
	if sz.x < 2.0 or sz.y < 2.0:
		return Vector2(800, 600)
	return sz


func _fit_zoom_for_pivot(pivot_rot: float) -> float:
	## World AABB of the board under the given pivot rotation, then fit in the viewport.
	var view := _view_size()
	var pad := PAD
	var corners: Array[Vector2] = [
		Vector2(_board_rect.position.x - pad, _board_rect.position.y - pad),
		Vector2(_board_rect.end.x + pad, _board_rect.position.y - pad),
		Vector2(_board_rect.end.x + pad, _board_rect.end.y + pad),
		Vector2(_board_rect.position.x - pad, _board_rect.end.y + pad),
	]
	var min_p := Vector2(INF, INF)
	var max_p := Vector2(-INF, -INF)
	for c in corners:
		var w := _pivot.position + c.rotated(pivot_rot)
		min_p = min_p.min(w)
		max_p = max_p.max(w)
	var size := (max_p - min_p).max(Vector2(1, 1))
	return clampf(minf(view.x / size.x, view.y / size.y), ZOOM_MIN, ZOOM_MAX)


func _fit_camera() -> void:
	if _board_rect.size.x <= 1.0:
		return
	var z := _fit_zoom_for_pivot(REST_PIVOT_ROT)
	_auto_orient = true
	_follow_rot_target = REST_PIVOT_ROT
	_follow_space_index = -1
	_follow_t = 0.0
	_camera.rotation = 0.0
	var world_center := _board_center()
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_camera, "zoom", Vector2(z, z), 0.55)
	tw.parallel().tween_property(_camera, "position", world_center, 0.55)
	tw.parallel().tween_property(_pivot, "rotation", REST_PIVOT_ROT, 0.55)


func _on_roll() -> void:
	if _busy or _sim.get_phase() != DistrictSim.PHASE_ROLL:
		return
	if _sim.get_player(_sim.get_current_player()).is_bot:
		return
	_run_action(func() -> Array: return _sim.roll())


func _on_buy() -> void:
	if _busy or _sim.get_phase() != DistrictSim.PHASE_BUY:
		return
	if _sim.get_player(_sim.get_current_player()).is_bot:
		return
	_run_action(func() -> Array: return _sim.buy())


func _on_skip() -> void:
	if _busy or _sim.get_phase() != DistrictSim.PHASE_BUY:
		return
	if _sim.get_player(_sim.get_current_player()).is_bot:
		return
	_run_action(func() -> Array: return _sim.skip())


func _run_action(action: Callable) -> void:
	_busy = true
	_set_actions_enabled(false)
	var events: Array = action.call()
	await _play_events(events)
	_busy = false
	_paint_owners()
	_refresh_hud()


func _play_events(events: Array) -> void:
	for item in events:
		var data := item as Dictionary
		var type_name := str(data.get("type", ""))
		match type_name:
			"rolled":
				_push_log(
					"P%d rolled [b]%d+%d[/b]"
					% [int(data.get("player", 0)) + 1, int(data.get("d1", 0)), int(data.get("d2", 0))]
				)
				await _animate_dice(int(data.get("d1", 1)), int(data.get("d2", 1)))
			"moved":
				var pid := int(data.get("player", 0))
				var from_i := int(data.get("from", 0))
				var to_i := int(data.get("to", 0))
				var steps := int(data.get("steps", 1))
				_push_log(
					"P%d → [color=#9ad0ff]%s[/color]"
					% [pid + 1, _sim.get_config().space_at(to_i).name]
				)
				await _animate_pawn_path(pid, from_i, to_i, steps)
			"bought":
				var space_i := int(data.get("space", 0))
				_push_log(
					"[color=#f0c35a]P%d bought %s[/color]"
					% [int(data.get("player", 0)) + 1, _sim.get_config().space_at(space_i).name]
				)
				await _pop_tile(space_i, Color(1.0, 0.85, 0.35, 1))
			"paid_rent":
				_push_log(
					"Rent [color=#ff8e8e]%d[/color]: P%d→P%d"
					% [int(data.get("amount", 0)), int(data.get("from", 0)) + 1, int(data.get("to", 0)) + 1]
				)
				_toast_cash(int(data.get("from", 0)), -int(data.get("amount", 0)))
				_toast_cash(int(data.get("to", 0)), int(data.get("amount", 0)))
			"taxed":
				_push_log("Tax %d on P%d" % [int(data.get("amount", 0)), int(data.get("player", 0)) + 1])
				_toast_cash(int(data.get("player", 0)), -int(data.get("amount", 0)))
			"passed_go":
				_push_log("[color=#7dcea0]P%d +$%d Plaza[/color]" % [int(data.get("player", 0)) + 1, int(data.get("amount", 0))])
				_toast_cash(int(data.get("player", 0)), int(data.get("amount", 0)))
			"went_to_jail":
				var jail_pid := int(data.get("player", 0))
				_push_log("[color=#d98880]P%d → Holding[/color]" % [jail_pid + 1])
				_snap_pawn(jail_pid, _sim.get_config().jail_index)
				await _shake_camera(0.25)
			"left_jail":
				_push_log("P%d left Holding" % [int(data.get("player", 0)) + 1])
			"bankrupt":
				_push_log("[color=#e74c3c]P%d bankrupt[/color]" % [int(data.get("player", 0)) + 1])
				await _shake_camera(0.35)
			"offer_buy":
				_push_log(
					"Offer: %s ($%d)"
					% [_sim.get_config().space_at(int(data.get("space", 0))).name, int(data.get("price", 0))]
				)
			"turn_changed":
				_push_log("— Turn P%d —" % [int(data.get("player", 0)) + 1])
			"game_over":
				_push_log("[b]Winner: P%d[/b]" % [int(data.get("winner", 0)) + 1])
			"skipped_buy":
				_push_log("P%d passed" % [int(data.get("player", 0)) + 1])
			_:
				_push_log(type_name)
		_sync_cash_toasts()
		_refresh_hud()


func _animate_dice(d1: int, d2: int) -> void:
	_die_a.texture = load("res://games/districts/assets/kenney_boardgame/dice/die_%d.png" % clampi(d1, 1, 6))
	_die_b.texture = load("res://games/districts/assets/kenney_boardgame/dice/die_%d.png" % clampi(d2, 1, 6))
	_dice_overlay.visible = true
	_dice_overlay.pivot_offset = _dice_overlay.size * 0.5
	_dice_overlay.modulate.a = 0.0
	_dice_overlay.scale = Vector2(0.6, 0.6)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_dice_overlay, "modulate:a", 1.0, 0.12)
	tw.tween_property(_dice_overlay, "scale", Vector2(1.15, 1.15), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	var settle := create_tween()
	settle.tween_property(_dice_overlay, "scale", Vector2.ONE, 0.1)
	await settle.finished
	await get_tree().create_timer(0.55).timeout
	var fade := create_tween()
	fade.tween_property(_dice_overlay, "modulate:a", 0.0, 0.2)
	await fade.finished
	_dice_overlay.visible = false
	_dice_overlay.modulate.a = 1.0
	_dice_overlay.scale = Vector2.ONE


func _animate_pawn_path(player_id: int, from_i: int, to_i: int, steps: int) -> void:
	if player_id < 0 or player_id >= _pawn_nodes.size():
		return
	var pawn := _pawn_nodes[player_id]
	var count := _sim.get_config().space_count()
	var cur := from_i
	_auto_orient = true
	for _s in maxi(steps, 1):
		cur = (cur + 1) % count
		var target := _tile_centers[cur] + _pawn_offset(player_id)
		_set_follow_space(cur)
		var hop := create_tween()
		hop.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		hop.tween_property(pawn, "position", target + Vector2(0, -14), STEP_SEC * 0.5)
		hop.tween_property(pawn, "position", target, STEP_SEC * 0.5)
		await hop.finished
		if cur < _tile_sprites.size():
			var flash := create_tween()
			flash.tween_property(_tile_sprites[cur], "modulate", Color(1.3, 1.3, 1.15, 1), 0.08)
			flash.tween_property(_tile_sprites[cur], "modulate", Color.WHITE, 0.18)
	pawn.position = _tile_centers[to_i] + _pawn_offset(player_id)
	_set_follow_space(to_i)
	_update_space_chip(to_i)


func _set_follow_space(space_i: int) -> void:
	if space_i < 0 or space_i >= _tile_centers.size():
		return
	_follow_space_index = space_i
	# Put this side at the bottom of the diamond view (readable band-outward layout).
	_follow_rot_target = REST_PIVOT_ROT - float(_space_side(space_i)) * (PI * 0.5)
	_follow_target = _framing_target()
	_follow_t = 1.2
	_auto_orient = true


func _tile_world_pos(space_i: int) -> Vector2:
	return _pivot.to_global(_tile_centers[space_i])


func _pop_tile(space_i: int, tint: Color) -> void:
	if space_i < 0 or space_i >= _tile_sprites.size():
		return
	var sprite := _tile_sprites[space_i]
	var tw := create_tween()
	tw.tween_property(sprite, "scale", Vector2(1.25, 1.25), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(sprite, "modulate", tint, 0.12)
	tw.tween_property(sprite, "scale", Vector2.ONE, 0.18)
	tw.parallel().tween_property(sprite, "modulate", Color.WHITE, 0.18)
	await tw.finished
	_burst_at(_tile_centers[space_i], tint)


func _burst_at(at: Vector2, tint: Color) -> void:
	for i in 8:
		var poly := Polygon2D.new()
		poly.polygon = PackedVector2Array([Vector2(-2, -2), Vector2(2, -2), Vector2(2, 2), Vector2(-2, 2)])
		poly.color = tint
		poly.position = at
		_fx.add_child(poly)
		var angle := TAU * float(i) / 8.0
		var dest := at + Vector2(cos(angle), sin(angle)) * 36.0
		var tw := create_tween()
		tw.tween_property(poly, "position", dest, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(poly, "modulate:a", 0.0, 0.28)
		tw.tween_callback(poly.queue_free)


func _shake_camera(amount: float) -> void:
	var base := _camera.position
	var tw := create_tween()
	for _i in 4:
		tw.tween_property(_camera, "position", base + Vector2(randf_range(-8, 8), randf_range(-6, 6)) * amount, 0.04)
	tw.tween_property(_camera, "position", base, 0.06)
	await tw.finished


func _toast_cash(player_id: int, delta_cash: int) -> void:
	if player_id < 0 or player_id >= _pawn_nodes.size() or delta_cash == 0:
		return
	var label := Label.new()
	label.text = ("%+d" % delta_cash)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override(
		"font_color",
		Color(0.45, 0.95, 0.65, 1) if delta_cash > 0 else Color(1.0, 0.45, 0.45, 1)
	)
	label.position = _svc.size * 0.5 + Vector2(float(player_id) * 18.0 - 30.0, -40.0)
	_toast_layer.add_child(label)
	var tw := create_tween()
	tw.tween_property(label, "position:y", label.position.y - 40.0, 0.7)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 0.7)
	tw.tween_callback(label.queue_free)


func _sync_cash_toasts() -> void:
	for i in _sim.get_player_count():
		var cash := _sim.get_player(i).cash
		if i < _cash_cache.size() and cash != _cash_cache[i]:
			_cash_cache[i] = cash
		elif i >= _cash_cache.size():
			_cash_cache.append(cash)


func _push_log(line: String) -> void:
	_log_lines.append(line)
	while _log_lines.size() > 12:
		_log_lines.remove_at(0)
	_log.text = "\n".join(_log_lines)
	_log.scroll_to_line(maxi(_log.get_line_count() - 1, 0))


func _snap_pawn(player_id: int, space_i: int) -> void:
	if player_id < 0 or player_id >= _pawn_nodes.size():
		return
	if space_i < 0 or space_i >= _tile_centers.size():
		return
	_pawn_nodes[player_id].position = _tile_centers[space_i] + _pawn_offset(player_id)
	_set_follow_space(space_i)
	_update_space_chip(space_i)


func _paint_owners() -> void:
	for i in _owner_pips.size():
		var owner := _sim.get_owner(i)
		var pip := _owner_pips[i]
		if owner >= 0:
			pip.visible = true
			pip.color = PAWN_COLORS[owner % PAWN_COLORS.size()]
		else:
			pip.visible = false


func _build_board() -> void:
	for child in _board.get_children():
		child.queue_free()
	_tile_sprites.clear()
	_owner_pips.clear()

	var absolute := _square_ring_centers(_sim.get_config().space_count())
	var min_p := Vector2(INF, INF)
	var max_p := Vector2(-INF, -INF)
	for center in absolute:
		min_p = min_p.min(center - TILE_HALF)
		max_p = max_p.max(center + TILE_HALF)
	var abs_rect := Rect2(min_p, max_p - min_p)
	var origin := abs_rect.get_center()
	_pivot.position = origin
	_pivot.rotation = REST_PIVOT_ROT
	_camera.rotation = 0.0

	_tile_centers.clear()
	for center in absolute:
		_tile_centers.append(center - origin)
	_board_rect = Rect2(-abs_rect.size * 0.5, abs_rect.size)

	_setup_table_surface()

	for i in _sim.get_config().space_count():
		var space := _sim.get_config().space_at(i)
		var local := _tile_centers[i]
		var sprite := Sprite2D.new()
		sprite.texture = DistrictTileBaker.bake(space)
		sprite.centered = true
		sprite.position = local
		sprite.rotation = _space_tile_rotation(i)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var pip := Polygon2D.new()
		pip.polygon = PackedVector2Array([
			Vector2(-5, 0), Vector2(0, -5), Vector2(5, 0), Vector2(0, 5),
		])
		# Toward board center in local tile space (band is at texture top / outer).
		pip.position = Vector2(0, 36)
		pip.visible = false
		pip.z_index = 2
		sprite.add_child(pip)
		_board.add_child(sprite)
		_tile_sprites.append(sprite)
		_owner_pips.append(pip)


func _setup_table_surface() -> void:
	var felt_tex: Texture2D = load("res://games/districts/assets/tiles/felt.png")
	_table_felt.texture = felt_tex
	_table_felt.centered = true
	_table_felt.position = Vector2.ZERO
	_table_felt.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var pad := 140.0
	var size := _board_rect.size + Vector2(pad, pad)
	if felt_tex != null:
		_table_felt.scale = Vector2(
			size.x / float(felt_tex.get_width()),
			size.y / float(felt_tex.get_height())
		)
	_table_felt.modulate = Color(0.75, 0.92, 0.8, 1)

	# Square plate filling the hollow center of the track.
	var inset := EDGE_H * 0.55
	var half := _board_rect.size * 0.5 - Vector2(inset, inset)
	half = half.max(Vector2(40, 40))
	_table_plate.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	_table_plate.color = Color(0.1, 0.28, 0.18, 1)
	_table_plate.position = Vector2.ZERO


func _build_pawns() -> void:
	for child in _pawns.get_children():
		child.queue_free()
	_pawn_nodes.clear()
	for i in _sim.get_player_count():
		var sprite := Sprite2D.new()
		sprite.texture = load(MEEPLE_PATHS[i % MEEPLE_PATHS.size()])
		sprite.centered = true
		sprite.scale = Vector2(0.85, 0.85)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.z_index = 10
		sprite.position = _tile_centers[0] + _pawn_offset(i)
		var shadow := Sprite2D.new()
		shadow.texture = sprite.texture
		shadow.centered = true
		shadow.modulate = Color(0, 0, 0, 0.35)
		shadow.position = Vector2(3, 5)
		shadow.z_index = -1
		sprite.add_child(shadow)
		_pawns.add_child(sprite)
		_pawn_nodes.append(sprite)


func _pawn_offset(player_id: int) -> Vector2:
	return Vector2(float(player_id) * 14.0 - 21.0, -30.0 - float(player_id % 2) * 10.0)


func _space_side(index: int) -> int:
	var per_side := maxi(_sim.get_config().space_count() / 4, 1)
	return clampi(int(index / per_side), 0, 3)


func _space_tile_rotation(index: int) -> float:
	## Texture band is at the top; rotate so the band faces the outer edge.
	match _space_side(index):
		0: # bottom, outer +Y
			return PI
		1: # right, outer +X
			return PI * 0.5
		2: # top, outer -Y
			return 0.0
		3: # left, outer -X
			return -PI * 0.5
	return 0.0


func _square_ring_centers(count: int) -> Array[Vector2]:
	var per := maxi(count / 4, 1)
	var edges := maxi(per - 1, 1)
	var corner_r := CORNER * 0.5
	var arm := float(edges) * EDGE_W * 0.5 + corner_r
	var centers: Array[Vector2] = []
	centers.resize(count)
	for i in count:
		var side := int(i / per)
		var slot := i % per
		var pos := Vector2.ZERO
		match side:
			0: # bottom: left → right
				if slot == 0:
					pos = Vector2(-arm, arm)
				else:
					var x0 := -arm + corner_r + EDGE_W * 0.5
					pos = Vector2(x0 + float(slot - 1) * EDGE_W, arm)
			1: # right: bottom → top
				if slot == 0:
					pos = Vector2(arm, arm)
				else:
					var y0 := arm - corner_r - EDGE_W * 0.5
					pos = Vector2(arm, y0 - float(slot - 1) * EDGE_W)
			2: # top: right → left
				if slot == 0:
					pos = Vector2(arm, -arm)
				else:
					var x0 := arm - corner_r - EDGE_W * 0.5
					pos = Vector2(x0 - float(slot - 1) * EDGE_W, -arm)
			3: # left: top → bottom
				if slot == 0:
					pos = Vector2(-arm, -arm)
				else:
					var y0 := -arm + corner_r + EDGE_W * 0.5
					pos = Vector2(-arm, y0 + float(slot - 1) * EDGE_W)
		centers[i] = pos
	return centers


func _highlight_current_tile() -> void:
	if _tile_sprites.is_empty() or _busy:
		return
	for sprite in _tile_sprites:
		sprite.scale = Vector2.ONE
	var player := _sim.get_player(_sim.get_current_player())
	if player.position >= 0 and player.position < _tile_sprites.size():
		var s := 1.0 + 0.07 * (0.5 + 0.5 * sin(_pulse * 3.5))
		_tile_sprites[player.position].scale = Vector2(s, s)
		_update_space_chip(player.position)


func _update_space_chip(space_i: int) -> void:
	if space_i < 0 or space_i >= _sim.get_config().space_count():
		_space_chip.visible = false
		return
	var space := _sim.get_config().space_at(space_i)
	var owner := _sim.get_owner(space_i)
	var owner_txt := ""
	if owner >= 0:
		owner_txt = " · P%d" % (owner + 1)
	_space_chip_label.text = "%s%s" % [space.name, owner_txt]
	_space_chip.visible = true


func _refresh_hud() -> void:
	for child in _roster.get_children():
		child.queue_free()
	for i in _sim.get_player_count():
		var player := _sim.get_player(i)
		var card := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.14, 0.18, 1)
		style.set_corner_radius_all(8)
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 6
		style.content_margin_bottom = 6
		if i == _sim.get_current_player():
			style.set_border_width_all(1)
			style.border_color = PAWN_COLORS[i % PAWN_COLORS.size()]
		card.add_theme_stylebox_override("panel", style)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(10, 28)
		swatch.color = PAWN_COLORS[i % PAWN_COLORS.size()]
		var text := Label.new()
		var bot := " · bot" if player.is_bot else ""
		var jail := " · jail" if player.in_jail else ""
		var dead := " · OUT" if player.bankrupt else ""
		text.text = "P%d%s\n$%d · %d props%s%s" % [
			i + 1, bot, player.cash, player.owned.size(), jail, dead,
		]
		text.add_theme_font_size_override("font_size", 13)
		text.add_theme_color_override("font_color", Color(0.9, 0.93, 0.97, 1))
		row.add_child(swatch)
		row.add_child(text)
		card.add_child(row)
		_roster.add_child(card)

	var phase := _sim.get_phase()
	_turn.text = "Seat %d · %s" % [_sim.get_current_player() + 1, phase.to_upper()]
	if phase == DistrictSim.PHASE_BUY and _sim.get_pending_space() >= 0:
		var space := _sim.get_config().space_at(_sim.get_pending_space())
		_offer.text = "Buy %s for $%d?" % [space.name, space.price]
		_offer.visible = true
	else:
		_offer.visible = false
	_set_actions_enabled(not _busy)
	if phase == DistrictSim.PHASE_OVER:
		_banner.visible = true
		_banner_label.text = "P%d holds the districts\nEnter — new match" % [_sim.get_winner() + 1]
		if not _banner_shown:
			_banner_shown = true
			_banner.pivot_offset = _banner.size * 0.5
			_banner.scale = Vector2(0.85, 0.85)
			_banner.modulate.a = 0.0
			var tw := create_tween().set_parallel(true)
			tw.tween_property(_banner, "modulate:a", 1.0, 0.2)
			tw.tween_property(_banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_banner.visible = false
		_banner_shown = false


func _set_actions_enabled(enabled: bool) -> void:
	var phase := _sim.get_phase()
	var human := not _sim.get_player(_sim.get_current_player()).is_bot
	_fit_btn.disabled = false
	_roll.disabled = not (enabled and phase == DistrictSim.PHASE_ROLL and human)
	_buy.disabled = not (enabled and phase == DistrictSim.PHASE_BUY and human)
	_skip.disabled = not (enabled and phase == DistrictSim.PHASE_BUY and human)
	if phase == DistrictSim.PHASE_OVER:
		_roll.disabled = true
		_buy.disabled = true
		_skip.disabled = true


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
