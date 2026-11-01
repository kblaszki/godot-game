extends "res://addons/gut/test.gd"


func test_same_seed_and_inputs_should_match() -> void:
	var left := _new_sim(11, PongConfig.new())
	var right := _new_sim(11, PongConfig.new())
	for step_index in 240:
		var dir := 0
		if step_index % 20 < 7:
			dir = -1
		elif step_index % 20 < 14:
			dir = 1
		left.set_input(dir, 1)
		right.set_input(dir, 1)
		assert_eq(left.step(), right.step())
	assert_eq(left.get_left_paddle_y(), right.get_left_paddle_y())
	assert_eq(left.get_right_paddle_y(), right.get_right_paddle_y())
	assert_eq(left.get_ball_position(), right.get_ball_position())
	assert_eq(left.get_ball_velocity(), right.get_ball_velocity())
	assert_eq(left.get_left_score(), right.get_left_score())
	assert_eq(left.get_right_score(), right.get_right_score())
	assert_eq(left.get_status(), right.get_status())


func test_ai_right_paddle_should_move_toward_ball() -> void:
	var config := PongConfig.new()
	var sim := _new_sim(3, config)
	var center_y := config.court_height * 0.5
	var ball_y := center_y + 80.0
	sim._ball_position = Vector2(config.court_width * 0.75, ball_y)
	sim._ball_velocity = Vector2.ZERO
	# -1 would move a player paddle toward smaller y. AI must chase the ball instead.
	sim.set_input(0, -1)
	var before := sim.get_right_paddle_y()
	sim.step()
	var after := sim.get_right_paddle_y()
	assert_gt(after, before)
	assert_lt(after, ball_y)
	assert_almost_eq(after - before, config.ai_speed * FixedTick.SEC, 0.001)
	assert_eq(sim.get_ball_position().y, ball_y)


func test_scoring_should_increment_and_eventually_game_over() -> void:
	var config := PongConfig.new()
	config.win_score = 2
	var sim := _new_sim(5, config)

	var right_point := _place_and_step(sim, config, -config.ball_radius - 1.0, -config.ball_speed)
	assert_eq(sim.get_right_score(), 1)
	assert_eq(sim.get_left_score(), 0)
	assert_eq(sim.get_status(), "scored")
	assert_true(_event_has(right_point, "scored", "side", "right"))
	assert_false(_event_has_type(right_point, "game_over"))

	_run_until_status(sim, "playing")

	var left_point := _place_and_step(
		sim, config, config.court_width + config.ball_radius + 1.0, config.ball_speed
	)
	assert_eq(sim.get_left_score(), 1)
	assert_eq(sim.get_right_score(), 1)
	assert_eq(sim.get_status(), "scored")
	assert_true(_event_has(left_point, "scored", "side", "left"))

	_run_until_status(sim, "playing")

	var winning := _place_and_step(sim, config, -config.ball_radius - 1.0, -config.ball_speed)
	assert_eq(sim.get_right_score(), 2)
	assert_eq(sim.get_left_score(), 1)
	assert_eq(sim.get_status(), "game_over")
	assert_true(_event_has(winning, "scored", "side", "right"))
	assert_true(_event_has(winning, "game_over", "winner", "right"))

	var extra := _place_and_step(sim, config, -config.ball_radius - 1.0, -config.ball_speed)
	assert_eq(extra.size(), 0)
	assert_eq(sim.get_right_score(), 2)
	assert_eq(sim.get_status(), "game_over")


func _new_sim(seed_value: int, config: PongConfig) -> PongSim:
	return PongSim.new(config, SeededRng.new(seed_value))


func _place_and_step(sim: PongSim, config: PongConfig, ball_x: float, velocity_x: float) -> Array:
	sim._ball_position = Vector2(ball_x, config.court_height * 0.5)
	sim._ball_velocity = Vector2(velocity_x, 0.0)
	return sim.step()


func _run_until_status(sim: PongSim, status: String) -> void:
	var guard := 0
	while sim.get_status() != status and guard < 180:
		sim.step()
		guard += 1
	assert_eq(sim.get_status(), status)


func _event_has(events: Array, type_name: String, key: String, value: String) -> bool:
	for event in events:
		if typeof(event) != TYPE_DICTIONARY:
			continue
		if str(event.get("type", "")) == type_name and str(event.get(key, "")) == value:
			return true
	return false


func _event_has_type(events: Array, type_name: String) -> bool:
	for event in events:
		if typeof(event) != TYPE_DICTIONARY:
			continue
		if str(event.get("type", "")) == type_name:
			return true
	return false
