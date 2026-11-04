extends Node2D

const MENU_PATH := "res://games/breakout/app/main_menu.tscn"
const PAUSE_PATH := "res://games/breakout/app/pause_menu.tscn"
const SCORE_PATH := "user://scores/breakout.txt"
const SCORE_CAPACITY := 10
const SERVE_SEED := 1
const TRAIL_LEN := 14

const PADDLE_TEX := preload("res://games/breakout/assets/paddle.png")
const BALL_TEX := preload("res://games/breakout/assets/ball.png")
const LIFE_TEX := preload("res://games/breakout/assets/life.png")
const BRICK_TEXES: Array[Texture2D] = [
	preload("res://games/breakout/assets/brick_0.png"),
	preload("res://games/breakout/assets/brick_1.png"),
	preload("res://games/breakout/assets/brick_2.png"),
	preload("res://games/breakout/assets/brick_3.png"),
	preload("res://games/breakout/assets/brick_4.png"),
]
const BRICK_TINTS: Array[Color] = [
	Color(1.0, 0.45, 0.55, 1),
	Color(1.0, 0.62, 0.35, 1),
	Color(0.4, 1.0, 0.82, 1),
	Color(0.45, 0.7, 1.0, 1),
	Color(0.78, 0.55, 1.0, 1),
]

var _config: BreakoutConfig
var _sim: BreakoutSim
var _input: InputState = InputState.new()
var _audio = NullAudio.new()
var _accum: float = 0.0
var _leaving: bool = false
var _score_saved: bool = false
var _brick_sprites: Array[Sprite2D] = []
var _life_sprites: Array[Sprite2D] = []
var _trail: PackedVector2Array = PackedVector2Array()
var _shake: float = 0.0
var _score_pulse: float = 0.0
var _time: float = 0.0
var _base_position: Vector2 = Vector2.ZERO

@onready var _sky: ColorRect = $Sky
@onready var _horizon: ColorRect = $Horizon
@onready var _floor_glow: ColorRect = $FloorGlow
@onready var _stars: Node2D = $Stars
@onready var _bricks: Node2D = $Bricks
@onready var _fx: Node2D = $Fx
@onready var _trail_line: Line2D = $Trail
@onready var _paddle_glow: ColorRect = $PaddleGlow
@onready var _paddle: Sprite2D = $Paddle
@onready var _ball: Sprite2D = $Ball
@onready var _score: Label = $Hud/Score
@onready var _score_hint: Label = $Hud/ScoreHint
@onready var _lives_root: Node2D = $Hud/Lives
@onready var _banner_dim: ColorRect = $Hud/BannerDim
@onready var _banner_panel: ColorRect = $Hud/BannerPanel
@onready var _banner_accent: ColorRect = $Hud/BannerAccent
@onready var _banner: Label = $Hud/Banner


func _ready() -> void:
	_config = BreakoutConfig.new()
	_sim = BreakoutSim.new(_config, SeededRng.new(SERVE_SEED))
	_audio = _find_audio()
	_layout()
	_fit_to_viewport()
	_sync_view()


func _process(delta: float) -> void:
	_time += delta
	_shake = maxf(0.0, _shake - delta * 8.0)
	_score_pulse = maxf(0.0, _score_pulse - delta * 4.0)
	var shake_offset := Vector2(
		sin(_time * 55.0) * _shake * 3.0,
		cos(_time * 47.0) * _shake * 2.0
	)
	position = _base_position + shake_offset
	_score.scale = Vector2.ONE * (1.0 + _score_pulse * 0.35)
	_animate_stars()
	_horizon.modulate = Color(1, 1, 1, 0.55 + 0.2 * sin(_time * 1.4))


func _physics_process(delta: float) -> void:
	var status := _sim.get_status()
	if status == "playing" or status == "life_lost":
		_sample_input()
		_sim.set_input(int(_input.get_axis(&"breakout_move_left", &"breakout_move_right")))
		_accum += delta
		while _accum >= FixedTick.SEC:
			_accum -= FixedTick.SEC
			_handle_events(_sim.step(FixedTick.SEC))
	_sync_view()


func _handle_events(events: Array) -> void:
	for item in events:
		var data := item as Dictionary
		match str(data.get("type", "")):
			"brick_broken":
				_audio.play(&"brick")
				_score_pulse = 1.0
				var row := int(data.get("row", 0))
				var col := int(data.get("col", 0))
				var rect := _sim.brick_rect(row, col)
				_burst(rect.get_center(), BRICK_TINTS[row % BRICK_TINTS.size()])
			"life_lost":
				_audio.play(&"die")
				_shake = 1.0
				_trail.clear()
			"game_over":
				_persist_score()
			"cleared":
				_audio.play(&"clear")
				_shake = 0.6
				_persist_score()


func _find_audio():
	var node: Node = get_parent()
	while node != null:
		if node.has_method("get_audio"):
			return node.call("get_audio")
		node = node.get_parent()
	return NullAudio.new()


func _persist_score() -> void:
	if _score_saved:
		return
	_score_saved = true
	var table := ScoreStore.load(SCORE_PATH, SCORE_CAPACITY)
	if table.insert(_sim.get_score()) >= 0:
		ScoreStore.save(SCORE_PATH, table)


func _unhandled_input(event: InputEvent) -> void:
	if _leaving or _sim == null:
		return
	var status := _sim.get_status()
	if status == "game_over" or status == "cleared":
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
			_leaving = true
			_submit(SceneRequest.replace(MENU_PATH))
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("breakout_pause"):
		_submit(SceneRequest.push(PAUSE_PATH))
		get_viewport().set_input_as_handled()


func _sample_input() -> void:
	_input.begin_frame()
	_input.set_action(&"breakout_move_left", Input.is_action_pressed("breakout_move_left"))
	_input.set_action(&"breakout_move_right", Input.is_action_pressed("breakout_move_right"))


func _layout() -> void:
	var w := _config.court_width
	var h := _config.court_height
	_sky.position = Vector2.ZERO
	_sky.size = Vector2(w, h)
	_horizon.position = Vector2(0.0, h * 0.42)
	_horizon.size = Vector2(w, h * 0.58)
	_floor_glow.position = Vector2(0.0, h - 56.0)
	_floor_glow.size = Vector2(w, 56.0)
	_build_stars()
	_paddle.texture = PADDLE_TEX
	_paddle.centered = false
	_paddle.scale = Vector2(
		_config.paddle_width / float(PADDLE_TEX.get_width()),
		_config.paddle_height / float(PADDLE_TEX.get_height())
	)
	_ball.texture = BALL_TEX
	_ball.centered = false
	var diameter := _config.ball_radius * 2.0
	_ball.scale = Vector2(
		diameter / float(BALL_TEX.get_width()),
		diameter / float(BALL_TEX.get_height())
	)
	_score_hint.position = Vector2(18.0, 10.0)
	_score.position = Vector2(18.0, 24.0)
	_score.size = Vector2(200.0, 36.0)
	_lives_root.position = Vector2(w - 18.0, 18.0)
	_banner_dim.position = Vector2.ZERO
	_banner_dim.size = Vector2(w, h)
	var panel_size := Vector2(460.0, 160.0)
	var panel_pos := (Vector2(w, h) - panel_size) * 0.5
	_banner_panel.position = panel_pos
	_banner_panel.size = panel_size
	_banner_accent.position = Vector2(panel_pos.x, panel_pos.y)
	_banner_accent.size = Vector2(8.0, panel_size.y)
	_banner.position = panel_pos
	_banner.size = panel_size
	_ensure_brick_sprites()
	_ensure_life_sprites()


func _fit_to_viewport() -> void:
	var content := Vector2(_config.court_width, _config.court_height)
	var fit := ViewFit.compute(content, get_viewport().get_visible_rect().size)
	var fit_scale: float = fit["scale"]
	scale = Vector2(fit_scale, fit_scale)
	_base_position = fit["offset"]
	position = _base_position


func _build_stars() -> void:
	for child in _stars.get_children():
		child.queue_free()
	var rng := SeededRng.new(42)
	for _i in 48:
		var star := ColorRect.new()
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var size := rng.randf_range(1.0, 2.6)
		star.size = Vector2(size, size)
		star.position = Vector2(
			rng.randf_range(0.0, _config.court_width),
			rng.randf_range(0.0, _config.court_height * 0.55)
		)
		star.color = Color(0.7, 0.85, 1.0, rng.randf_range(0.25, 0.85))
		star.set_meta("phase", rng.randf_range(0.0, TAU))
		star.set_meta("speed", rng.randf_range(1.2, 3.5))
		_stars.add_child(star)


func _animate_stars() -> void:
	for star in _stars.get_children():
		var phase: float = star.get_meta("phase")
		var speed: float = star.get_meta("speed")
		star.modulate.a = 0.25 + 0.55 * (0.5 + 0.5 * sin(_time * speed + phase))


func _ensure_brick_sprites() -> void:
	var needed := _config.brick_rows * _config.brick_cols
	while _brick_sprites.size() < needed:
		var sprite := Sprite2D.new()
		sprite.centered = false
		_bricks.add_child(sprite)
		_brick_sprites.append(sprite)


func _ensure_life_sprites() -> void:
	while _life_sprites.size() < _config.start_lives:
		var sprite := Sprite2D.new()
		sprite.texture = LIFE_TEX
		sprite.centered = false
		sprite.scale = Vector2(2.2, 2.2)
		_lives_root.add_child(sprite)
		_life_sprites.append(sprite)


func _sync_view() -> void:
	var paddle_pos := Vector2(
		_sim.get_paddle_x() - _config.paddle_width * 0.5,
		_sim.get_paddle_y() - _config.paddle_height * 0.5
	)
	_paddle.position = paddle_pos
	_paddle_glow.position = paddle_pos + Vector2(-10.0, 4.0)
	_paddle_glow.size = Vector2(_config.paddle_width + 20.0, _config.paddle_height + 14.0)
	var ball := _sim.get_ball_position()
	_ball.position = ball - Vector2(_config.ball_radius, _config.ball_radius)
	_update_trail(ball)
	for row in _config.brick_rows:
		for col in _config.brick_cols:
			var index := row * _config.brick_cols + col
			var sprite: Sprite2D = _brick_sprites[index]
			var alive := _sim.is_brick_alive(row, col)
			sprite.visible = alive
			if alive:
				var brick := _sim.brick_rect(row, col)
				var tex: Texture2D = BRICK_TEXES[row % BRICK_TEXES.size()]
				sprite.texture = tex
				sprite.modulate = Color(1.05, 1.05, 1.1, 1)
				sprite.position = brick.position
				sprite.scale = Vector2(
					brick.size.x / float(tex.get_width()),
					brick.size.y / float(tex.get_height())
				)
	_score.text = str(_sim.get_score())
	for i in _life_sprites.size():
		var life: Sprite2D = _life_sprites[i]
		life.visible = i < _sim.get_lives()
		life.position = Vector2(-float(i + 1) * 28.0, 0.0)
	var status := _sim.get_status()
	var over := status == "game_over" or status == "cleared"
	_banner_dim.visible = over
	_banner_panel.visible = over
	_banner_accent.visible = over
	_banner.visible = over
	if status == "cleared":
		_banner.text = "SHATTERED\nEnter — continue"
		_banner_accent.color = Color(0.35, 1.0, 0.75, 1)
	elif status == "game_over":
		_banner.text = "OUT OF ORBIT\nEnter — menu"
		_banner_accent.color = Color(1.0, 0.4, 0.55, 1)


func _update_trail(ball: Vector2) -> void:
	if _sim.get_status() != "playing":
		_trail_line.points = PackedVector2Array()
		return
	_trail.append(ball)
	while _trail.size() > TRAIL_LEN:
		_trail.remove_at(0)
	_trail_line.points = _trail
	_trail_line.default_color = Color(1.0, 0.9, 0.45, 0.15 + 0.35 * (_trail.size() / float(TRAIL_LEN)))


func _burst(at: Vector2, tint: Color) -> void:
	for i in 10:
		var speck := ColorRect.new()
		speck.mouse_filter = Control.MOUSE_FILTER_IGNORE
		speck.size = Vector2(3, 3)
		speck.position = at
		speck.color = tint
		_fx.add_child(speck)
		var angle := TAU * float(i) / 10.0 + _time
		var vel := Vector2(cos(angle), sin(angle)) * (90.0 + float(i) * 12.0)
		_fly_speck(speck, vel)


func _fly_speck(speck: ColorRect, vel: Vector2) -> void:
	var life := 0.35
	var elapsed := 0.0
	while elapsed < life and is_instance_valid(speck):
		var dt := get_process_delta_time()
		elapsed += dt
		speck.position += vel * dt
		speck.modulate.a = 1.0 - elapsed / life
		await get_tree().process_frame
	if is_instance_valid(speck):
		speck.queue_free()


func _submit(req: SceneRequest) -> void:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("submit"):
			node.call("submit", req)
			return
		node = node.get_parent()
