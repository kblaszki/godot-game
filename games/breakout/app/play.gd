extends Node2D

const MENU_PATH := "res://games/breakout/app/main_menu.tscn"
const PAUSE_PATH := "res://games/breakout/app/pause_menu.tscn"
const SERVE_SEED := 1

const BRICK_COLORS: Array[Color] = [
	Color(0.92, 0.35, 0.35, 1),
	Color(0.95, 0.55, 0.25, 1),
	Color(0.95, 0.85, 0.3, 1),
	Color(0.35, 0.8, 0.45, 1),
	Color(0.35, 0.55, 0.95, 1),
]

var _config: BreakoutConfig
var _sim: BreakoutSim
var _input: InputState = InputState.new()
var _accum: float = 0.0
var _leaving: bool = false
var _brick_rects: Array[ColorRect] = []

@onready var _background: ColorRect = $Background
@onready var _paddle: ColorRect = $Paddle
@onready var _ball: ColorRect = $Ball
@onready var _bricks: Node2D = $Bricks
@onready var _hud: Label = $Hud/Status
@onready var _banner_panel: ColorRect = $Hud/BannerPanel
@onready var _banner: Label = $Hud/Banner


func _ready() -> void:
	_config = BreakoutConfig.new()
	_sim = BreakoutSim.new(_config, SeededRng.new(SERVE_SEED))
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
			_sim.step(FixedTick.SEC)
	_sync_view()


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
	_paddle.size = Vector2(_config.paddle_width, _config.paddle_height)
	var diameter := _config.ball_radius * 2.0
	_ball.size = Vector2(diameter, diameter)
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
	_ensure_brick_rects()


func _fit_to_viewport() -> void:
	var content := Vector2(_config.court_width, _config.court_height)
	var fit := ViewFit.compute(content, get_viewport().get_visible_rect().size)
	var fit_scale: float = fit["scale"]
	scale = Vector2(fit_scale, fit_scale)
	position = fit["offset"]


func _ensure_brick_rects() -> void:
	var needed := _config.brick_rows * _config.brick_cols
	while _brick_rects.size() < needed:
		var rect := ColorRect.new()
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bricks.add_child(rect)
		_brick_rects.append(rect)


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
			var rect: ColorRect = _brick_rects[index]
			var alive := _sim.is_brick_alive(row, col)
			rect.visible = alive
			if alive:
				var brick := _sim.brick_rect(row, col)
				rect.position = brick.position
				rect.size = brick.size
				rect.color = BRICK_COLORS[row % BRICK_COLORS.size()]
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
