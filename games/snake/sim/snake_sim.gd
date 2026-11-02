class_name SnakeSim
extends RefCounted

var _config: SnakeConfig
var _rng: SeededRng
var _segments: Array[Vector2i] = []
var _food: Vector2i = Vector2i.ZERO
var _dir: Vector2i = Vector2i(1, 0)
var _pending_dir: Vector2i = Vector2i(1, 0)
var _score: int = 0
var _status: String = "playing"
var _tick_accum: int = 0
var _grow: int = 0


func _init(config: SnakeConfig, rng: SeededRng) -> void:
	_config = config
	_rng = rng
	reset()


func reset() -> void:
	_score = 0
	_status = "playing"
	_tick_accum = 0
	_grow = 0
	_dir = Vector2i(1, 0)
	_pending_dir = _dir
	_segments.clear()
	var mid := Vector2i(_config.width / 2, _config.height / 2)
	var length: int = maxi(1, _config.start_length)
	for i in length:
		_segments.append(mid - Vector2i(i, 0))
	_place_food()


## Latches a desired direction. Applied on the next move tick if not a 180° reverse.
func set_input(dx: int, dy: int) -> void:
	dx = clampi(dx, -1, 1)
	dy = clampi(dy, -1, 1)
	if dx == 0 and dy == 0:
		return
	# Cardinal only: prefer non-zero axis if both set (ignore diagonals).
	if dx != 0 and dy != 0:
		return
	_pending_dir = Vector2i(dx, dy)


func step(dt: float = FixedTick.SEC) -> Array:
	var events: Array = []
	if _status == "game_over":
		return events
	# Fixed-tick sim: count steps; ignore wall-clock magnitude beyond one tick unit.
	_tick_accum += 1
	if _tick_accum < _config.move_every_ticks:
		return events
	_tick_accum = 0
	_apply_pending_direction()
	var next_head: Vector2i = _segments[0] + _dir
	if _hits_wall(next_head) or _hits_body(next_head):
		_status = "game_over"
		events.append({"type": "game_over"})
		return events
	_segments.insert(0, next_head)
	if next_head == _food:
		_score += 1
		_grow += 1
		events.append({"type": "ate"})
		_place_food()
	if _grow > 0:
		_grow -= 1
	else:
		_segments.pop_back()
	return events


func get_segments() -> Array[Vector2i]:
	return _segments.duplicate()


func get_food() -> Vector2i:
	return _food


func get_score() -> int:
	return _score


func get_status() -> String:
	return _status


func get_direction() -> Vector2i:
	return _dir


func _apply_pending_direction() -> void:
	if _pending_dir.x == -_dir.x and _pending_dir.y == -_dir.y:
		return
	if _pending_dir == Vector2i.ZERO:
		return
	_dir = _pending_dir


func _hits_wall(cell: Vector2i) -> bool:
	return cell.x < 0 or cell.y < 0 or cell.x >= _config.width or cell.y >= _config.height


func _hits_body(cell: Vector2i) -> bool:
	# Tail will vacate unless growing; allow moving into current tail.
	var last: int = _segments.size() - 1
	for i in _segments.size():
		if _grow == 0 and i == last:
			continue
		if _segments[i] == cell:
			return true
	return false


func _place_food() -> void:
	var empty: Array[Vector2i] = []
	for y in _config.height:
		for x in _config.width:
			var cell := Vector2i(x, y)
			if not _segments.has(cell):
				empty.append(cell)
	if empty.is_empty():
		_food = Vector2i(-1, -1)
		return
	var index: int = _rng.randi_range(0, empty.size() - 1)
	_food = empty[index]
