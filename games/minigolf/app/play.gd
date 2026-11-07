extends Control

const PAUSE_PATH := "res://games/minigolf/app/pause_menu.tscn"
const RESULTS_PATH := "res://games/minigolf/app/results.tscn"

var _sim: MinigolfSim
var _busy: bool = false
var _bot_cooldown: float = 0.35
var _power_held: bool = false
var _power_t: float = 0.0
var _drag_last: Vector2 = Vector2.ZERO
var _scorecard_open: bool = false
var _shown_hole: int = -1
var _going_results: bool = false

@onready var _svc: SubViewportContainer = $BoardRoot/SubViewportContainer
@onready var _viewport: SubViewport = $BoardRoot/SubViewportContainer/SubViewport
@onready var _course: Course3D = $BoardRoot/SubViewportContainer/SubViewport/Course3D
@onready var _audio: MinigolfAudio = $MinigolfAudio
@onready var _status: Label = $TopBar/Status
@onready var _feed: Label = $BottomBar/Feed
@onready var _power_bar: ProgressBar = $PowerBar
@onready var _scorecard: PanelContainer = $Scorecard
@onready var _score_label: Label = $Scorecard/Margin/ScoreLabel
@onready var _fit_btn: Button = $TopBar/Fit


func _ready() -> void:
	var players := 2
	var bot_mask := 0
	var seed_value := 1
	var host := _find_host()
	if host != null:
		players = int(host.get("match_players"))
		bot_mask = int(host.get("match_bot_mask"))
		seed_value = int(host.get("match_seed"))
	_sim = MinigolfSim.new(MinigolfConfig.new(), SeededRng.new(seed_value))
	_sim.setup(players, bot_mask, CourseCatalog.FAIRWAY_PARK, seed_value)
	if OS.has_feature("headless") or DisplayServer.get_name() == "headless":
		_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_fit_btn.pressed.connect(_on_fit)
	_svc.gui_input.connect(_on_board_gui_input)
	_svc.resized.connect(func() -> void: _course.fit(_svc.size))
	_scorecard.visible = false
	_power_bar.visible = false
	_reload_hole()
	_refresh_hud()
	_push_feed("Click green to aim. Hold Space for power, release to putt. F fit · Tab card · Esc pause.")
	await get_tree().process_frame
	if is_inside_tree():
		_course.fit(_svc.size)


func _process(delta: float) -> void:
	if _sim == null or _going_results:
		return
	if _power_held and (_sim.get_phase() == MinigolfSim.PHASE_AIM or _sim.get_phase() == MinigolfSim.PHASE_POWER):
		_power_t = minf(1.0, _power_t + delta * 0.7)
		_power_bar.visible = true
		_power_bar.value = _power_t * 100.0
		_sim.set_power(_power_t)

	match _sim.get_phase():
		MinigolfSim.PHASE_COURSE_OVER:
			_open_results()
			return
		MinigolfSim.PHASE_HOLE_RESULT:
			if not _busy:
				_handle_events(_sim.advance_after_hole())
			return
		MinigolfSim.PHASE_MOVING:
			_handle_events(_sim.tick(3))
			return

	if _busy:
		return
	var player := _sim.get_player(_sim.get_current_player())
	if player.is_bot and (_sim.get_phase() == MinigolfSim.PHASE_AIM or _sim.get_phase() == MinigolfSim.PHASE_POWER):
		_bot_cooldown -= delta
		if _bot_cooldown <= 0.0:
			_bot_cooldown = 0.4
			_busy = true
			_handle_events(_sim.bot_act())
			_busy = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_submit(SceneRequest.push(PAUSE_PATH))
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		if key.keycode == KEY_TAB:
			_scorecard_open = not _scorecard_open
			_scorecard.visible = _scorecard_open
			_refresh_scorecard()
			get_viewport().set_input_as_handled()
		elif key.keycode == KEY_F:
			_on_fit()
			get_viewport().set_input_as_handled()
		elif key.keycode == KEY_SPACE:
			if not _busy and not _sim.get_player(_sim.get_current_player()).is_bot:
				if _sim.get_phase() == MinigolfSim.PHASE_AIM or _sim.get_phase() == MinigolfSim.PHASE_POWER:
					_power_held = true
					_power_t = 0.05
					get_viewport().set_input_as_handled()
	if event is InputEventKey and not event.pressed and (event as InputEventKey).keycode == KEY_SPACE:
		if _power_held:
			_power_held = false
			_power_bar.visible = false
			if not _busy and not _sim.get_player(_sim.get_current_player()).is_bot:
				_sim.set_power(_power_t)
				_busy = true
				_handle_events(_sim.stroke())
				_busy = false
			get_viewport().set_input_as_handled()


func _on_board_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_course.begin_orbit()
				_drag_last = mb.position
			else:
				_course.end_orbit()
			_svc.accept_event()
		elif mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			if mb.pressed:
				_course.begin_pan()
				_drag_last = mb.position
			else:
				_course.end_pan()
			_svc.accept_event()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_course.dolly(1.1)
			_svc.accept_event()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_course.dolly(1.0 / 1.1)
			_svc.accept_event()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var delta := mm.position - _drag_last
		_drag_last = mm.position
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_course.orbit(delta.x)
			_svc.accept_event()
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			_course.pan(delta)
			_svc.accept_event()
		elif not _busy and not _sim.get_player(_sim.get_current_player()).is_bot:
			if _sim.get_phase() == MinigolfSim.PHASE_AIM or _sim.get_phase() == MinigolfSim.PHASE_POWER:
				_aim_from_screen(mm.position)


func _aim_from_screen(screen_pos: Vector2) -> void:
	var view := _svc.size
	if view.x < 2.0:
		return
	var local := (screen_pos - view * 0.5) / maxf(view.y, 1.0)
	var dir := Vector2(local.x, -local.y)
	if dir.length_squared() < 0.0001:
		return
	_sim.set_aim(dir.normalized())
	_course.set_aim_dir(_sim.get_aim(), _sim.get_ball().pos)


func _on_fit() -> void:
	_course.fit(_svc.size)


func _reload_hole() -> void:
	_shown_hole = _sim.get_hole_index()
	var hole := _sim.get_hole()
	_course.setup_hole(hole, hole.id == "h6")
	_course.set_ball_pos(_sim.get_ball().pos, 1.0)
	_course.set_aim_dir(_sim.get_aim(), _sim.get_ball().pos)
	_course.fit(_svc.size)


func _handle_events(events: Array) -> void:
	for item in events:
		var data := item as Dictionary
		match str(data.get("type", "")):
			"stroke_started":
				_course.hide_aim()
				_course.set_follow_ball(true)
				_audio.play_cue("putt")
				_push_feed("P%d putts…" % (int(data.get("player", 0)) + 1))
			"ball_moved":
				_course.set_ball_pos(data.get("pos", _sim.get_ball().pos), 0.65)
			"bounced":
				_course.punch_camera(0.12)
				_audio.play_cue("bounce")
			"stopped":
				_course.set_follow_ball(false)
				_course.set_ball_pos(_sim.get_ball().pos, 1.0)
				_course.set_aim_dir(_sim.get_aim(), _sim.get_ball().pos)
			"sunk":
				_course.set_follow_ball(false)
				_course.set_ball_pos(_sim.get_hole().cup_xz(), 1.0)
				_audio.play_cue("sink")
				var strokes := int(data.get("strokes", 0))
				if strokes == 1:
					_push_feed("Hole-in-one!")
					_burst_confetti()
				else:
					_push_feed("Sunk in %d (par %d)" % [strokes, int(data.get("par", 3))])
			"oob_reset":
				_push_feed("Out of bounds — replaced")
				_course.set_ball_pos(_sim.get_ball().pos, 1.0)
			"hole_complete":
				_push_feed("Hole %d complete" % (int(data.get("hole_index", 0)) + 1))
			"turn_changed":
				_push_feed("P%d to play" % (int(data.get("player", 0)) + 1))
			"course_complete":
				_push_feed("Course complete")
	if _sim.get_hole_index() != _shown_hole:
		_reload_hole()
	else:
		_course.set_ball_pos(_sim.get_ball().pos, 1.0)
	_refresh_hud()


func _open_results() -> void:
	_going_results = true
	var host := _find_host()
	if host != null:
		host.set_meta("match_rankings", _sim.get_rankings())
		host.set_meta("match_totals", _totals())
		host.set_meta("match_card", _card_rows())
	_submit(SceneRequest.replace(RESULTS_PATH))


func _totals() -> PackedInt32Array:
	var out := PackedInt32Array()
	for i in _sim.get_player_count():
		out.append(_sim.get_player(i).total())
	return out


func _card_rows() -> Array:
	var rows: Array = []
	for i in _sim.get_player_count():
		rows.append({"seat": i, "strokes": _sim.get_player(i).hole_strokes, "total": _sim.get_player(i).total()})
	return rows


func _refresh_hud() -> void:
	var hole := _sim.get_hole()
	_status.text = "Hole %d/%d · Par %d · Stroke %d · P%d" % [
		_sim.get_hole_index() + 1,
		_sim.get_hole_count(),
		hole.par,
		_sim.get_ball().strokes,
		_sim.get_current_player() + 1,
	]
	if _scorecard_open:
		_refresh_scorecard()


func _refresh_scorecard() -> void:
	var lines: PackedStringArray = PackedStringArray(["Scorecard"])
	for i in _sim.get_player_count():
		var p := _sim.get_player(i)
		lines.append("P%d  total %d  %s" % [i + 1, p.total(), str(p.hole_strokes)])
	_score_label.text = "\n".join(lines)


func _push_feed(text: String) -> void:
	_feed.text = text


func _burst_confetti() -> void:
	for i in 12:
		var bit := ColorRect.new()
		bit.size = Vector2(8, 8)
		bit.color = Color(randf(), randf(), randf(), 1)
		bit.position = size * 0.5 + Vector2(randf_range(-40, 40), -20)
		add_child(bit)
		var tw := create_tween()
		tw.tween_property(bit, "position", bit.position + Vector2(randf_range(-120, 120), randf_range(-160, -40)), 0.7)
		tw.parallel().tween_property(bit, "modulate:a", 0.0, 0.7)
		tw.tween_callback(bit.queue_free)


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
