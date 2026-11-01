class_name PongSim
extends RefCounted

## Seconds the rally stays in "scored" before the next serve.
const SCORED_HOLD_SEC := 0.5
const SERVE_ANGLE := 0.45
const MAX_BOUNCE_ANGLE := 0.85

var _config: PongConfig
var _rng: SeededRng
var _left_dir: int = 0
var _left_paddle_y: float = 0.0
var _right_paddle_y: float = 0.0
var _ball_position: Vector2 = Vector2.ZERO
var _ball_velocity: Vector2 = Vector2.ZERO
var _left_score: int = 0
var _right_score: int = 0
var _status: String = "playing"
var _scored_hold: float = 0.0


func _init(config: PongConfig, rng: SeededRng) -> void:
	_config = config
	_rng = rng
	reset()


func reset() -> void:
	_left_score = 0
	_right_score = 0
	_status = "playing"
	_scored_hold = 0.0
	_left_dir = 0
	_left_paddle_y = _config.court_height * 0.5
	_right_paddle_y = _config.court_height * 0.5
	_serve()


## Latches paddle directions. -1 decreases y, +1 increases y, 0 holds.
## The right paddle is AI-controlled; right_dir is ignored.
func set_input(left_dir: int, _right_dir: int) -> void:
	_left_dir = clampi(left_dir, -1, 1)


func step(dt: float = FixedTick.SEC) -> Array:
	var events: Array = []
	if _status == "game_over":
		return events
	if _status == "scored":
		_scored_hold -= dt
		if _scored_hold <= 0.0:
			_serve()
			_status = "playing"
		return events
	_move_left_paddle(dt)
	_move_ai_paddle(dt)
	_ball_position += _ball_velocity * dt
	_resolve_vertical_walls()
	_resolve_paddles()
	_resolve_goals(events)
	return events


func get_left_paddle_y() -> float:
	return _left_paddle_y


func get_right_paddle_y() -> float:
	return _right_paddle_y


func get_ball_position() -> Vector2:
	return _ball_position


func get_ball_velocity() -> Vector2:
	return _ball_velocity


func get_left_score() -> int:
	return _left_score


func get_right_score() -> int:
	return _right_score


func get_status() -> String:
	return _status


func _serve() -> void:
	_ball_position = Vector2(_config.court_width * 0.5, _config.court_height * 0.5)
	var dir_x := -1.0
	if _rng.randi_range(0, 1) == 1:
		dir_x = 1.0
	var angle := _rng.randf_range(-SERVE_ANGLE, SERVE_ANGLE)
	_ball_velocity = Vector2(cos(angle) * dir_x, sin(angle)) * _config.ball_speed


func _move_left_paddle(dt: float) -> void:
	_left_paddle_y += float(_left_dir) * _config.paddle_speed * dt
	_left_paddle_y = _clamp_paddle_y(_left_paddle_y)


func _move_ai_paddle(dt: float) -> void:
	var delta := _ball_position.y - _right_paddle_y
	var max_step := _config.ai_speed * dt
	if absf(delta) <= max_step:
		_right_paddle_y = _ball_position.y
	else:
		_right_paddle_y += signf(delta) * max_step
	_right_paddle_y = _clamp_paddle_y(_right_paddle_y)


func _clamp_paddle_y(y: float) -> float:
	var half := _config.paddle_height * 0.5
	return clampf(y, half, _config.court_height - half)


func _resolve_vertical_walls() -> void:
	var top := _config.ball_radius
	var bottom := _config.court_height - _config.ball_radius
	if _ball_position.y < top:
		_ball_position.y = top
		_ball_velocity.y = absf(_ball_velocity.y)
	elif _ball_position.y > bottom:
		_ball_position.y = bottom
		_ball_velocity.y = -absf(_ball_velocity.y)


func _resolve_paddles() -> void:
	if _ball_velocity.x < 0.0 and _overlaps_paddle(_left_paddle_x(), _left_paddle_y):
		var face_x := _left_paddle_x() + _config.paddle_width * 0.5 + _config.ball_radius
		_bounce(1.0, _left_paddle_y, face_x)
	elif _ball_velocity.x > 0.0 and _overlaps_paddle(_right_paddle_x(), _right_paddle_y):
		var face_x := _right_paddle_x() - _config.paddle_width * 0.5 - _config.ball_radius
		_bounce(-1.0, _right_paddle_y, face_x)


func _resolve_goals(events: Array) -> void:
	if _ball_position.x + _config.ball_radius < 0.0:
		_award("right", events)
	elif _ball_position.x - _config.ball_radius > _config.court_width:
		_award("left", events)


func _award(side: String, events: Array) -> void:
	if side == "left":
		_left_score += 1
	else:
		_right_score += 1
	events.append({"type": "scored", "side": side})
	var score := _left_score if side == "left" else _right_score
	_ball_velocity = Vector2.ZERO
	if score >= _config.win_score:
		_status = "game_over"
		events.append({"type": "game_over", "winner": side})
	else:
		_status = "scored"
		_scored_hold = SCORED_HOLD_SEC


func _overlaps_paddle(paddle_x: float, paddle_y: float) -> bool:
	var half_w := _config.paddle_width * 0.5 + _config.ball_radius
	var half_h := _config.paddle_height * 0.5 + _config.ball_radius
	var dx := absf(_ball_position.x - paddle_x)
	var dy := absf(_ball_position.y - paddle_y)
	return dx <= half_w and dy <= half_h


func _bounce(dir_x: float, paddle_y: float, separated_x: float) -> void:
	var half_h := _config.paddle_height * 0.5
	var offset := 0.0
	if half_h > 0.0:
		offset = clampf((_ball_position.y - paddle_y) / half_h, -1.0, 1.0)
	var angle := offset * MAX_BOUNCE_ANGLE
	_ball_velocity = Vector2(cos(angle) * dir_x, sin(angle)) * _config.ball_speed
	_ball_position.x = separated_x


func _left_paddle_x() -> float:
	return _config.paddle_width * 0.5


func _right_paddle_x() -> float:
	return _config.court_width - _config.paddle_width * 0.5
