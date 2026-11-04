class_name BreakoutSim
extends RefCounted

const LIFE_LOST_HOLD_SEC := 0.5
const SERVE_ANGLE := 0.55
const MAX_BOUNCE_ANGLE := 1.0

var _config: BreakoutConfig
var _rng: SeededRng
var _paddle_dir: int = 0
var _paddle_x: float = 0.0
var _ball_position: Vector2 = Vector2.ZERO
var _ball_velocity: Vector2 = Vector2.ZERO
var _bricks: Array[bool] = []
var _bricks_alive: int = 0
var _score: int = 0
var _lives: int = 0
var _status: String = "playing"
var _life_hold: float = 0.0


func _init(config: BreakoutConfig, rng: SeededRng) -> void:
	_config = config
	_rng = rng
	reset()


func reset() -> void:
	_score = 0
	_lives = _config.start_lives
	_status = "playing"
	_life_hold = 0.0
	_paddle_dir = 0
	_paddle_x = _config.court_width * 0.5
	_init_bricks()
	_serve()


func set_input(dir: int) -> void:
	_paddle_dir = clampi(dir, -1, 1)


func step(dt: float = FixedTick.SEC) -> Array:
	var events: Array = []
	if _status == "game_over" or _status == "cleared":
		return events
	if _status == "life_lost":
		_life_hold -= dt
		if _life_hold <= 0.0:
			_serve()
			_status = "playing"
		return events
	_move_paddle(dt)
	_ball_position += _ball_velocity * dt
	_resolve_walls()
	_resolve_paddle()
	_resolve_bricks(events)
	_resolve_bottom(events)
	return events


func get_paddle_x() -> float:
	return _paddle_x


func get_paddle_y() -> float:
	return _config.court_height - _config.paddle_margin_bottom


func get_ball_position() -> Vector2:
	return _ball_position


func get_ball_velocity() -> Vector2:
	return _ball_velocity


func get_score() -> int:
	return _score


func get_lives() -> int:
	return _lives


func get_status() -> String:
	return _status


func get_bricks_alive() -> int:
	return _bricks_alive


func is_brick_alive(row: int, col: int) -> bool:
	var index := _brick_index(row, col)
	if index < 0 or index >= _bricks.size():
		return false
	return _bricks[index]


func brick_rect(row: int, col: int) -> Rect2:
	var origin := _brick_grid_origin()
	var x := origin.x + float(col) * (_config.brick_width + _config.brick_gap)
	var y := origin.y + float(row) * (_config.brick_height + _config.brick_gap)
	return Rect2(x, y, _config.brick_width, _config.brick_height)


func _init_bricks() -> void:
	_bricks.clear()
	var total := maxi(_config.brick_rows, 0) * maxi(_config.brick_cols, 0)
	_bricks.resize(total)
	for i in total:
		_bricks[i] = true
	_bricks_alive = total


func _brick_index(row: int, col: int) -> int:
	if row < 0 or col < 0 or row >= _config.brick_rows or col >= _config.brick_cols:
		return -1
	return row * _config.brick_cols + col


func _brick_grid_origin() -> Vector2:
	var cols := maxi(_config.brick_cols, 0)
	var total_w := float(cols) * _config.brick_width
	if cols > 1:
		total_w += float(cols - 1) * _config.brick_gap
	var start_x := (_config.court_width - total_w) * 0.5
	return Vector2(start_x, _config.brick_offset_top)


func _serve() -> void:
	_ball_position = Vector2(_paddle_x, get_paddle_y() - _config.paddle_height * 0.5 - _config.ball_radius - 2.0)
	var angle := _rng.randf_range(-SERVE_ANGLE, SERVE_ANGLE)
	_ball_velocity = Vector2(sin(angle), -cos(angle)) * _config.ball_speed


func _move_paddle(dt: float) -> void:
	_paddle_x += float(_paddle_dir) * _config.paddle_speed * dt
	var half := _config.paddle_width * 0.5
	_paddle_x = clampf(_paddle_x, half, _config.court_width - half)


func _resolve_walls() -> void:
	var r := _config.ball_radius
	if _ball_position.x < r:
		_ball_position.x = r
		_ball_velocity.x = absf(_ball_velocity.x)
	elif _ball_position.x > _config.court_width - r:
		_ball_position.x = _config.court_width - r
		_ball_velocity.x = -absf(_ball_velocity.x)
	if _ball_position.y < r:
		_ball_position.y = r
		_ball_velocity.y = absf(_ball_velocity.y)


func _resolve_paddle() -> void:
	if _ball_velocity.y <= 0.0:
		return
	var paddle_y := get_paddle_y()
	var half_w := _config.paddle_width * 0.5 + _config.ball_radius
	var half_h := _config.paddle_height * 0.5 + _config.ball_radius
	var dx := absf(_ball_position.x - _paddle_x)
	var dy := absf(_ball_position.y - paddle_y)
	if dx > half_w or dy > half_h:
		return
	var offset := 0.0
	var paddle_half := _config.paddle_width * 0.5
	if paddle_half > 0.0:
		offset = clampf((_ball_position.x - _paddle_x) / paddle_half, -1.0, 1.0)
	var angle := offset * MAX_BOUNCE_ANGLE
	_ball_velocity = Vector2(sin(angle), -cos(angle)) * _config.ball_speed
	_ball_position.y = paddle_y - _config.paddle_height * 0.5 - _config.ball_radius


func _resolve_bricks(events: Array) -> void:
	for row in _config.brick_rows:
		for col in _config.brick_cols:
			var index := _brick_index(row, col)
			if index < 0 or not _bricks[index]:
				continue
			var rect := brick_rect(row, col)
			if not _ball_hits_rect(rect):
				continue
			_bricks[index] = false
			_bricks_alive -= 1
			_score += _config.points_per_brick
			events.append({"type": "brick_broken", "row": row, "col": col})
			_bounce_off_rect(rect)
			if _bricks_alive <= 0:
				_status = "cleared"
				_ball_velocity = Vector2.ZERO
				events.append({"type": "cleared"})
			return


func _resolve_bottom(events: Array) -> void:
	if _status != "playing":
		return
	if _ball_position.y - _config.ball_radius <= _config.court_height:
		return
	_lives -= 1
	_ball_velocity = Vector2.ZERO
	events.append({"type": "life_lost", "lives": _lives})
	if _lives <= 0:
		_status = "game_over"
		events.append({"type": "game_over"})
	else:
		_status = "life_lost"
		_life_hold = LIFE_LOST_HOLD_SEC


func _ball_hits_rect(rect: Rect2) -> bool:
	var closest := Vector2(
		clampf(_ball_position.x, rect.position.x, rect.position.x + rect.size.x),
		clampf(_ball_position.y, rect.position.y, rect.position.y + rect.size.y)
	)
	return closest.distance_squared_to(_ball_position) <= _config.ball_radius * _config.ball_radius


func _bounce_off_rect(rect: Rect2) -> void:
	var cx := rect.position.x + rect.size.x * 0.5
	var cy := rect.position.y + rect.size.y * 0.5
	var dx := _ball_position.x - cx
	var dy := _ball_position.y - cy
	var px := rect.size.x * 0.5 + _config.ball_radius - absf(dx)
	var py := rect.size.y * 0.5 + _config.ball_radius - absf(dy)
	if px < py:
		_ball_velocity.x = absf(_ball_velocity.x) if dx > 0.0 else -absf(_ball_velocity.x)
		_ball_position.x = cx + signf(dx) * (rect.size.x * 0.5 + _config.ball_radius)
	else:
		_ball_velocity.y = absf(_ball_velocity.y) if dy > 0.0 else -absf(_ball_velocity.y)
		_ball_position.y = cy + signf(dy) * (rect.size.y * 0.5 + _config.ball_radius)
