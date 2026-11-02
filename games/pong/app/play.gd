extends Node2D

const MENU_PATH := "res://games/pong/app/main_menu.tscn"
const PAUSE_PATH := "res://games/pong/app/pause_menu.tscn"
const SERVE_SEED := 1

var _config: PongConfig
var _sim: PongSim
var _input: InputState = InputState.new()
var _accum: float = 0.0
var _winner: String = ""
var _leaving: bool = false

@onready var _background: ColorRect = $Background
@onready var _net: ColorRect = $Net
@onready var _left: ColorRect = $LeftPaddle
@onready var _right: ColorRect = $RightPaddle
@onready var _ball: ColorRect = $Ball
@onready var _score: Label = $Hud/Score
@onready var _banner_panel: ColorRect = $Hud/BannerPanel
@onready var _banner: Label = $Hud/Banner


func _ready() -> void:
	_config = PongConfig.new()
	_sim = PongSim.new(_config, SeededRng.new(SERVE_SEED))
	_layout()
	_sync_view()


func _physics_process(delta: float) -> void:
	if _sim.get_status() != "game_over":
		_sample_input()
		_sim.set_input(int(_input.get_axis(&"pong_move_up", &"pong_move_down")), 0)
		_accum += delta
		while _accum >= FixedTick.SEC:
			_accum -= FixedTick.SEC
			_collect(_sim.step(FixedTick.SEC))
	_sync_view()


func _unhandled_input(event: InputEvent) -> void:
	if _leaving or _sim == null:
		return
	var status := _sim.get_status()
	if status == "game_over":
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
			_leaving = true
			_submit(SceneRequest.replace(MENU_PATH))
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pong_pause"):
		_submit(SceneRequest.push(PAUSE_PATH))
		get_viewport().set_input_as_handled()


func _sample_input() -> void:
	_input.begin_frame()
	_input.set_action(&"pong_move_up", Input.is_action_pressed("pong_move_up"))
	_input.set_action(&"pong_move_down", Input.is_action_pressed("pong_move_down"))


func _collect(events: Array) -> void:
	for item in events:
		var data := item as Dictionary
		if data.get("type", "") == "game_over":
			_winner = str(data.get("winner", ""))


func _layout() -> void:
	_background.position = Vector2.ZERO
	_background.size = Vector2(_config.court_width, _config.court_height)
	_net.position = Vector2(_config.court_width * 0.5 - 1.0, 0.0)
	_net.size = Vector2(2.0, _config.court_height)
	_left.size = Vector2(_config.paddle_width, _config.paddle_height)
	_right.size = Vector2(_config.paddle_width, _config.paddle_height)
	var diameter := _config.ball_radius * 2.0
	_ball.size = Vector2(diameter, diameter)
	_score.position = Vector2(0.0, 12.0)
	_score.size = Vector2(_config.court_width, 40.0)
	var panel_size := Vector2(460.0, 150.0)
	var panel_pos := Vector2(
		(_config.court_width - panel_size.x) * 0.5,
		(_config.court_height - panel_size.y) * 0.5
	)
	_banner_panel.position = panel_pos
	_banner_panel.size = panel_size
	_banner.position = panel_pos
	_banner.size = panel_size


func _sync_view() -> void:
	_place_paddle(_left, _config.paddle_width * 0.5, _sim.get_left_paddle_y())
	_place_paddle(_right, _config.court_width - _config.paddle_width * 0.5, _sim.get_right_paddle_y())
	var ball := _sim.get_ball_position()
	_ball.position = ball - Vector2(_config.ball_radius, _config.ball_radius)
	_score.text = "%d    %d" % [_sim.get_left_score(), _sim.get_right_score()]
	var over := _sim.get_status() == "game_over"
	_banner_panel.visible = over
	_banner.visible = over
	if over:
		_banner.text = "%s wins\nEnter or Escape for menu" % _winner_name()


func _place_paddle(rect: ColorRect, center_x: float, center_y: float) -> void:
	rect.position = Vector2(
		center_x - _config.paddle_width * 0.5,
		center_y - _config.paddle_height * 0.5
	)


func _winner_name() -> String:
	if _winner == "left":
		return "Left"
	if _winner == "right":
		return "Right"
	return "Game over"


func _submit(req: SceneRequest) -> void:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("submit"):
			node.call("submit", req)
			return
		node = node.get_parent()
