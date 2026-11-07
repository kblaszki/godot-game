class_name MinigolfSim
extends RefCounted

const PHASE_AIM := "aim"
const PHASE_POWER := "power"
const PHASE_MOVING := "moving"
const PHASE_HOLE_RESULT := "hole_result"
const PHASE_COURSE_OVER := "course_over"

var _config: MinigolfConfig
var _rng: SeededRng
var _holes: Array[HoleDef] = []
var _players: Array[PlayerScore] = []
var _ball: BallState = BallState.new()
var _phase: String = PHASE_AIM
var _current: int = 0
var _hole_index: int = 0
var _aim: Vector2 = Vector2(0, 1)
var _power: float = 0.5
var _tick_count: int = 0
var _move_emit_counter: int = 0
var _winner: int = -1
var _rankings: PackedInt32Array = PackedInt32Array()


func _init(config: MinigolfConfig = null, rng: SeededRng = null) -> void:
	_config = config if config != null else MinigolfConfig.new()
	_rng = rng if rng != null else SeededRng.new(1)


func setup(player_count: int, bot_mask: int = 0, course_id: String = CourseCatalog.FAIRWAY_PARK, seed_value: int = 1) -> void:
	_rng = SeededRng.new(seed_value)
	_config.course_id = course_id
	_holes = CourseCatalog.build(course_id)
	var count := clampi(player_count, _config.min_players, _config.max_players)
	_players.clear()
	for i in count:
		var is_bot := (bot_mask & (1 << i)) != 0
		_players.append(PlayerScore.new(is_bot, _holes.size()))
	_hole_index = 0
	_current = 0
	_winner = -1
	_rankings = PackedInt32Array()
	_reset_ball_for_current()
	_phase = PHASE_AIM
	_aim = Vector2(0, 1)
	_power = 0.5
	_tick_count = 0


func get_phase() -> String:
	return _phase


func get_current_player() -> int:
	return _current


func get_player_count() -> int:
	return _players.size()


func get_player(index: int) -> PlayerScore:
	return _players[index]


func get_ball() -> BallState:
	return _ball


func get_config() -> MinigolfConfig:
	return _config


func get_hole_index() -> int:
	return _hole_index


func get_hole_count() -> int:
	return _holes.size()


func get_hole() -> HoleDef:
	return _holes[_hole_index]


func get_aim() -> Vector2:
	return _aim


func get_power() -> float:
	return _power


func get_winner() -> int:
	return _winner


func get_rankings() -> PackedInt32Array:
	return _rankings


func get_rng() -> SeededRng:
	return _rng


func set_aim(dir: Vector2) -> Array:
	var events: Array = []
	if _phase != PHASE_AIM and _phase != PHASE_POWER:
		return events
	if dir.length_squared() < 0.0001:
		return events
	_aim = dir.normalized()
	events.append({"type": "aim_changed", "player": _current, "dir": _aim})
	return events


func set_power(t: float) -> Array:
	var events: Array = []
	if _phase != PHASE_AIM and _phase != PHASE_POWER:
		return events
	_power = clampf(t, 0.0, 1.0)
	_phase = PHASE_POWER
	events.append({"type": "power_changed", "player": _current, "power": _power})
	return events


func stroke() -> Array:
	var events: Array = []
	if _phase != PHASE_AIM and _phase != PHASE_POWER:
		return events
	if _ball.sunk:
		return events
	var hole := get_hole()
	var max_s := _config.max_strokes_for_par(hole.par)
	if _ball.strokes >= max_s:
		return concede_hole()
	var dir := _aim if _aim.length_squared() > 0.0001 else Vector2(0, 1)
	dir = dir.normalized()
	var impulse := dir * (_power * _config.max_impulse)
	_ball.vel = impulse
	_ball.strokes += 1
	_players[_current].hole_strokes[_hole_index] = _ball.strokes
	_phase = PHASE_MOVING
	_tick_count = 0
	_move_emit_counter = 0
	events.append({
		"type": "stroke_started",
		"player": _current,
		"dir": dir,
		"power": _power,
		"impulse": impulse,
	})
	return events


func tick(n: int = 1) -> Array:
	var events: Array = []
	if _phase != PHASE_MOVING:
		return events
	for _i in maxi(n, 1):
		if _phase != PHASE_MOVING:
			break
		events.append_array(_integrate_once())
	return events


func resolve_stroke() -> Array:
	var events: Array = []
	if _phase != PHASE_MOVING:
		return events
	while _phase == PHASE_MOVING and _tick_count < _config.max_ticks_per_stroke:
		events.append_array(_integrate_once())
	if _phase == PHASE_MOVING:
		_ball.vel = Vector2.ZERO
		events.append({"type": "stopped", "pos": _ball.pos})
		_after_ball_stop(events)
	return events


func concede_hole() -> Array:
	var events: Array = []
	if _phase == PHASE_COURSE_OVER or _phase == PHASE_HOLE_RESULT:
		return events
	var hole := get_hole()
	var max_s := _config.max_strokes_for_par(hole.par)
	_ball.strokes = max_s
	_ball.sunk = true
	_ball.vel = Vector2.ZERO
	_players[_current].hole_strokes[_hole_index] = max_s
	events.append({"type": "sunk", "player": _current, "strokes": max_s, "par": hole.par, "conceded": true})
	_finish_player_hole(events)
	return events


func advance_after_hole() -> Array:
	var events: Array = []
	if _phase != PHASE_HOLE_RESULT:
		return events
	_hole_index += 1
	if _hole_index >= _holes.size():
		_finish_course(events)
		return events
	for p in _players:
		p.finished_hole = false
	_current = 0
	_reset_ball_for_current()
	_phase = PHASE_AIM
	_aim = Vector2(0, 1)
	_power = 0.5
	events.append({"type": "turn_changed", "player": _current, "hole": _hole_index})
	return events


func bot_act() -> Array:
	if _phase == PHASE_COURSE_OVER:
		return []
	var player := _players[_current]
	if not player.is_bot:
		return []
	match _phase:
		PHASE_AIM, PHASE_POWER:
			var pick := MinigolfBot.pick_aim_power(self)
			var events: Array = []
			events.append_array(set_aim(pick["dir"]))
			events.append_array(set_power(float(pick["power"])))
			events.append_array(stroke())
			events.append_array(resolve_stroke())
			return events
		PHASE_MOVING:
			return resolve_stroke()
		PHASE_HOLE_RESULT:
			return advance_after_hole()
	return []


func _reset_ball_for_current() -> void:
	var hole := get_hole()
	_ball = BallState.new()
	_ball.radius = _config.ball_radius
	_ball.pos = hole.tee_xz()
	_ball.last_fairway = _ball.pos
	_ball.vel = Vector2.ZERO
	_ball.sunk = false
	_ball.strokes = 0


func _integrate_once() -> Array:
	var events: Array = []
	_tick_count += 1
	var dt := _config.tick
	var hole := get_hole()

	# Damp pads: extra friction while inside.
	var damp := 1.0
	for pad in hole.damp_pads:
		var pmin: Vector2 = pad["min"]
		var pmax: Vector2 = pad["max"]
		if _ball.pos.x >= pmin.x and _ball.pos.x <= pmax.x and _ball.pos.y >= pmin.y and _ball.pos.y <= pmax.y:
			damp = float(pad.get("factor", 0.5))
			break

	var friction := _config.friction * damp
	_ball.vel *= maxf(0.0, 1.0 - friction * dt)
	_ball.pos += _ball.vel * dt

	events.append_array(_resolve_blockers(hole))
	events.append_array(_resolve_walls(hole))

	if not hole.contains_xz(_ball.pos):
		_ball.pos = _ball.last_fairway
		_ball.vel = Vector2.ZERO
		events.append({"type": "oob_reset", "pos": _ball.pos})
		_after_ball_stop(events)
		return events

	_ball.last_fairway = _ball.pos

	var to_cup := hole.cup_xz() - _ball.pos
	if to_cup.length() <= _config.cup_radius and _ball.speed() <= _config.sink_speed:
		_ball.sunk = true
		_ball.vel = Vector2.ZERO
		_ball.pos = hole.cup_xz()
		events.append({"type": "sunk", "player": _current, "strokes": _ball.strokes, "par": hole.par})
		_finish_player_hole(events)
		return events

	_move_emit_counter += 1
	if _move_emit_counter >= _config.ball_moved_every:
		_move_emit_counter = 0
		events.append({"type": "ball_moved", "pos": _ball.pos, "vel": _ball.vel})

	if _ball.speed() < _config.stop_eps:
		_ball.vel = Vector2.ZERO
		events.append({"type": "stopped", "pos": _ball.pos})
		_after_ball_stop(events)
		return events

	if _tick_count >= _config.max_ticks_per_stroke:
		_ball.vel = Vector2.ZERO
		events.append({"type": "stopped", "pos": _ball.pos})
		_after_ball_stop(events)
	return events


func _resolve_walls(hole: HoleDef) -> Array:
	var events: Array = []
	for wall in hole.walls:
		var a: Vector2 = wall["a"]
		var b: Vector2 = wall["b"]
		var hit := _circle_segment_push(_ball.pos, _ball.radius, a, b)
		if hit["hit"]:
			_ball.pos = hit["pos"]
			var n: Vector2 = hit["normal"]
			var vn := _ball.vel.dot(n)
			if vn < 0.0:
				_ball.vel = (_ball.vel - n * (1.0 + _config.restitution) * vn)
				events.append({"type": "bounced", "normal": n, "speed": _ball.speed()})
	return events


func _resolve_blockers(hole: HoleDef) -> Array:
	var events: Array = []
	for blocker in hole.blockers:
		var c: Vector2 = blocker["center"]
		var r: float = float(blocker["radius"]) + _ball.radius
		var delta := _ball.pos - c
		var dist := delta.length()
		if dist < r and dist > 0.0001:
			var n := delta / dist
			_ball.pos = c + n * r
			var vn := _ball.vel.dot(n)
			if vn < 0.0:
				_ball.vel = _ball.vel - n * (1.0 + _config.restitution) * vn
				events.append({"type": "bounced", "normal": n, "speed": _ball.speed()})
	return events


func _circle_segment_push(center: Vector2, radius: float, a: Vector2, b: Vector2) -> Dictionary:
	var ab := b - a
	var len_sq := ab.length_squared()
	var t := 0.0 if len_sq <= 0.000001 else clampf((center - a).dot(ab) / len_sq, 0.0, 1.0)
	var closest := a + ab * t
	var delta := center - closest
	var dist := delta.length()
	if dist >= radius or dist <= 0.000001:
		return {"hit": false}
	var n := delta / dist
	return {"hit": true, "pos": closest + n * radius, "normal": n}


func _after_ball_stop(events: Array) -> void:
	if _ball.sunk:
		return
	var hole := get_hole()
	var max_s := _config.max_strokes_for_par(hole.par)
	if _ball.strokes >= max_s:
		_ball.sunk = true
		_players[_current].hole_strokes[_hole_index] = max_s
		events.append({"type": "sunk", "player": _current, "strokes": max_s, "par": hole.par, "conceded": true})
		_finish_player_hole(events)
		return
	_phase = PHASE_AIM
	_power = 0.5


func _finish_player_hole(events: Array) -> void:
	_players[_current].finished_hole = true
	_players[_current].hole_strokes[_hole_index] = _ball.strokes
	if _all_finished_current_hole():
		events.append({
			"type": "hole_complete",
			"hole_index": _hole_index,
			"scores_slice": _scores_slice(),
		})
		_phase = PHASE_HOLE_RESULT
	else:
		_current = _next_unfinished()
		_reset_ball_for_current()
		_phase = PHASE_AIM
		_aim = Vector2(0, 1)
		_power = 0.5
		events.append({"type": "turn_changed", "player": _current, "hole": _hole_index})


func _all_finished_current_hole() -> bool:
	for p in _players:
		if not p.finished_hole:
			return false
	return true


func _next_unfinished() -> int:
	for i in _players.size():
		var idx := (_current + 1 + i) % _players.size()
		if not _players[idx].finished_hole:
			return idx
	return _current


func _scores_slice() -> PackedInt32Array:
	var out := PackedInt32Array()
	out.resize(_players.size())
	for i in _players.size():
		out[i] = _players[i].hole_strokes[_hole_index]
	return out


func _finish_course(events: Array) -> void:
	_rankings = _compute_rankings()
	_winner = _rankings[0] if _rankings.size() > 0 else 0
	_phase = PHASE_COURSE_OVER
	events.append({"type": "course_complete", "winner": _winner, "rankings": _rankings})


func _compute_rankings() -> PackedInt32Array:
	var order: Array[int] = []
	for i in _players.size():
		order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool:
		var ta := _players[a].total()
		var tb := _players[b].total()
		if ta != tb:
			return ta < tb
		var la := _players[a].hole_strokes[_holes.size() - 1]
		var lb := _players[b].hole_strokes[_holes.size() - 1]
		if la != lb:
			return la < lb
		var ha := _players[a].hole_in_ones()
		var hb := _players[b].hole_in_ones()
		if ha != hb:
			return ha > hb
		return a < b
	)
	var out := PackedInt32Array()
	for i in order.size():
		out.append(order[i])
	return out
