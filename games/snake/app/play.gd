extends Node2D

const MENU_PATH := "res://games/snake/app/main_menu.tscn"
const PAUSE_PATH := "res://games/snake/app/pause_menu.tscn"
const SCORE_PATH := "user://scores/snake.txt"
const SCORE_CAPACITY := 10
const FOOD_SEED := 1

var _config: SnakeConfig
var _sim: SnakeSim
var _input: InputState = InputState.new()
var _audio = NullAudio.new()
var _accum: float = 0.0
var _leaving: bool = false
var _score_saved: bool = false
var _body_rects: Array[ColorRect] = []

@onready var _board: ColorRect = $Board
@onready var _food: ColorRect = $Food
@onready var _bodies: Node2D = $Bodies
@onready var _score: Label = $Hud/Score
@onready var _banner_panel: ColorRect = $Hud/BannerPanel
@onready var _banner: Label = $Hud/Banner


func _ready() -> void:
	_config = SnakeConfig.new()
	_sim = SnakeSim.new(_config, SeededRng.new(FOOD_SEED))
	_audio = _find_audio()
	_layout_board()
	_sync_view()


func _physics_process(delta: float) -> void:
	if _sim.get_status() != "game_over":
		_apply_input()
		_accum += delta
		while _accum >= FixedTick.SEC:
			_accum -= FixedTick.SEC
			_handle_events(_sim.step(FixedTick.SEC))
	_sync_view()


func _handle_events(events: Array) -> void:
	for item in events:
		var data := item as Dictionary
		match str(data.get("type", "")):
			"ate":
				_audio.play(&"eat")
			"game_over":
				_audio.play(&"die")
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
	if _sim.get_status() == "game_over":
		if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
			_leaving = true
			_submit(SceneRequest.replace(MENU_PATH))
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("snake_pause"):
		_submit(SceneRequest.push(PAUSE_PATH))
		get_viewport().set_input_as_handled()


func _apply_input() -> void:
	_input.begin_frame()
	_input.set_action(&"snake_left", Input.is_action_pressed("snake_left"))
	_input.set_action(&"snake_right", Input.is_action_pressed("snake_right"))
	_input.set_action(&"snake_up", Input.is_action_pressed("snake_up"))
	_input.set_action(&"snake_down", Input.is_action_pressed("snake_down"))
	if _input.is_action_pressed(&"snake_left"):
		_sim.set_input(-1, 0)
	elif _input.is_action_pressed(&"snake_right"):
		_sim.set_input(1, 0)
	elif _input.is_action_pressed(&"snake_up"):
		_sim.set_input(0, -1)
	elif _input.is_action_pressed(&"snake_down"):
		_sim.set_input(0, 1)


func _layout_board() -> void:
	var board_size := Vector2(_config.width * _config.cell, _config.height * _config.cell)
	_board.position = Vector2.ZERO
	_board.size = board_size
	_score.position = Vector2(0.0, board_size.y + 8.0)
	_score.size = Vector2(board_size.x, 32.0)
	var panel_size := Vector2(360.0, 120.0)
	var panel_pos := (board_size - panel_size) * 0.5
	_banner_panel.position = panel_pos
	_banner_panel.size = panel_size
	_banner.position = panel_pos
	_banner.size = panel_size


func _sync_view() -> void:
	var cell := _config.cell
	var food := _sim.get_food()
	_food.visible = food.x >= 0
	_food.position = Vector2(food.x, food.y) * cell
	_food.size = Vector2(cell, cell)
	var segments: Array[Vector2i] = _sim.get_segments()
	while _body_rects.size() < segments.size():
		var rect := ColorRect.new()
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.color = Color(0.35, 0.85, 0.45, 1)
		_bodies.add_child(rect)
		_body_rects.append(rect)
	while _body_rects.size() > segments.size():
		var extra: ColorRect = _body_rects.pop_back()
		extra.queue_free()
	for i in segments.size():
		var rect: ColorRect = _body_rects[i]
		rect.position = Vector2(segments[i]) * cell
		rect.size = Vector2(cell, cell)
		rect.color = Color(0.55, 0.95, 0.55, 1) if i == 0 else Color(0.3, 0.75, 0.4, 1)
	_score.text = "Score: %d" % _sim.get_score()
	var over := _sim.get_status() == "game_over"
	_banner_panel.visible = over
	_banner.visible = over
	if over:
		_banner.text = "Game over\nEnter or Escape for menu"


func _submit(req: SceneRequest) -> void:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("submit"):
			node.call("submit", req)
			return
		node = node.get_parent()
