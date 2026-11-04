extends Node2D

const MENU_PATH := "res://games/breakout/app/main_menu.tscn"
const PAUSE_PATH := "res://games/breakout/app/pause_menu.tscn"
const SCORE_PATH := "user://scores/breakout.txt"
const SCORE_CAPACITY := 10
const SERVE_SEED := 1

const PADDLE_TEX := preload("res://games/breakout/assets/paddle.png")
const BALL_TEX := preload("res://games/breakout/assets/ball.png")
const BRICK_TEXES: Array[Texture2D] = [
	preload("res://games/breakout/assets/brick_0.png"),
	preload("res://games/breakout/assets/brick_1.png"),
	preload("res://games/breakout/assets/brick_2.png"),
	preload("res://games/breakout/assets/brick_3.png"),
	preload("res://games/breakout/assets/brick_4.png"),
]

var _config: BreakoutConfig
var _sim: BreakoutSim
var _input: InputState = InputState.new()
var _audio = NullAudio.new()
var _accum: float = 0.0
var _leaving: bool = false
var _score_saved: bool = false
var _brick_sprites: Array[Sprite2D] = []

@onready var _background: ColorRect = $Background
@onready var _paddle: Sprite2D = $Paddle
@onready var _ball: Sprite2D = $Ball
@onready var _bricks: Node2D = $Bricks
@onready var _hud: Label = $Hud/Status
@onready var _banner_panel: ColorRect = $Hud/BannerPanel
@onready var _banner: Label = $Hud/Banner


func _ready() -> void:
	_config = BreakoutConfig.new()
	_sim = BreakoutSim.new(_config, SeededRng.new(SERVE_SEED))
	_audio = _find_audio()
	_layout()
	_fit_to_viewport()
	_sync_view()


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
			"life_lost":
				_audio.play(&"die")
			"game_over":
				_persist_score()
			"cleared":
				_audio.play(&"clear")
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
	_background.position = Vector2.ZERO
	_background.size = Vector2(_config.court_width, _config.court_height)
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
	_hud.position = Vector2(12.0, 8.0)
	_hud.size = Vector2(_config.court_width - 24.0, 28.0)
	var panel_size := Vector2(420.0, 140.0)
	var panel_pos := Vector2(
		(_config.court_width - panel_size.x) * 0.5,
		(_config.court_height - panel_size.y) * 0.5
	)
	_banner_panel.position = panel_pos
	_banner_panel.size = panel_size
	_banner.position = panel_pos
	_banner.size = panel_size
	_ensure_brick_sprites()


func _fit_to_viewport() -> void:
	var content := Vector2(_config.court_width, _config.court_height)
	var fit := ViewFit.compute(content, get_viewport().get_visible_rect().size)
	var fit_scale: float = fit["scale"]
	scale = Vector2(fit_scale, fit_scale)
	position = fit["offset"]


func _ensure_brick_sprites() -> void:
	var needed := _config.brick_rows * _config.brick_cols
	while _brick_sprites.size() < needed:
		var sprite := Sprite2D.new()
		sprite.centered = false
		_bricks.add_child(sprite)
		_brick_sprites.append(sprite)


func _sync_view() -> void:
	_paddle.position = Vector2(
		_sim.get_paddle_x() - _config.paddle_width * 0.5,
		_sim.get_paddle_y() - _config.paddle_height * 0.5
	)
	var ball := _sim.get_ball_position()
	_ball.position = ball - Vector2(_config.ball_radius, _config.ball_radius)
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
				sprite.position = brick.position
				sprite.scale = Vector2(
					brick.size.x / float(tex.get_width()),
					brick.size.y / float(tex.get_height())
				)
	_hud.text = "Score: %d    Lives: %d" % [_sim.get_score(), _sim.get_lives()]
	var status := _sim.get_status()
	var over := status == "game_over" or status == "cleared"
	_banner_panel.visible = over
	_banner.visible = over
	if status == "cleared":
		_banner.text = "Cleared!\nEnter or Escape for menu"
	elif status == "game_over":
		_banner.text = "Game over\nEnter or Escape for menu"


func _submit(req: SceneRequest) -> void:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("submit"):
			node.call("submit", req)
			return
		node = node.get_parent()
