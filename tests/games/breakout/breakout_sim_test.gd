extends "res://addons/gut/test.gd"


func test_same_seed_and_inputs_should_match() -> void:
	var left := _new_sim(11, BreakoutConfig.new())
	var right := _new_sim(11, BreakoutConfig.new())
	for step_index in 240:
		var dir := 0
		if step_index % 20 < 7:
			dir = -1
		elif step_index % 20 < 14:
			dir = 1
		left.set_input(dir)
		right.set_input(dir)
		assert_eq(left.step(), right.step())
	assert_eq(left.get_paddle_x(), right.get_paddle_x())
	assert_eq(left.get_ball_position(), right.get_ball_position())
	assert_eq(left.get_ball_velocity(), right.get_ball_velocity())
	assert_eq(left.get_score(), right.get_score())
	assert_eq(left.get_lives(), right.get_lives())
	assert_eq(left.get_bricks_alive(), right.get_bricks_alive())
	assert_eq(left.get_status(), right.get_status())


func test_breaking_brick_should_score_and_decrement_alive() -> void:
	var config := BreakoutConfig.new()
	config.brick_rows = 1
	config.brick_cols = 1
	config.brick_offset_top = 100.0
	var sim := _new_sim(1, config)
	assert_eq(sim.get_bricks_alive(), 1)
	var rect := sim.brick_rect(0, 0)
	sim._ball_position = Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y + config.ball_radius - 1.0)
	sim._ball_velocity = Vector2(0.0, -config.ball_speed)
	var events := sim.step()
	assert_true(_event_has_type(events, "brick_broken"))
	assert_eq(sim.get_bricks_alive(), 0)
	assert_eq(sim.get_score(), config.points_per_brick)
	assert_eq(sim.get_status(), "cleared")
	assert_true(_event_has_type(events, "cleared"))


func test_ball_past_bottom_should_lose_life_then_game_over() -> void:
	var config := BreakoutConfig.new()
	config.start_lives = 2
	var sim := _new_sim(2, config)
	sim._ball_position = Vector2(config.court_width * 0.5, config.court_height + config.ball_radius + 1.0)
	sim._ball_velocity = Vector2(0.0, config.ball_speed)
	var first := sim.step()
	assert_eq(sim.get_lives(), 1)
	assert_eq(sim.get_status(), "life_lost")
	assert_true(_event_has_type(first, "life_lost"))
	assert_false(_event_has_type(first, "game_over"))

	_run_until_status(sim, "playing")

	sim._ball_position = Vector2(config.court_width * 0.5, config.court_height + config.ball_radius + 1.0)
	sim._ball_velocity = Vector2(0.0, config.ball_speed)
	var second := sim.step()
	assert_eq(sim.get_lives(), 0)
	assert_eq(sim.get_status(), "game_over")
	assert_true(_event_has_type(second, "life_lost"))
	assert_true(_event_has_type(second, "game_over"))

	var extra := sim.step()
	assert_eq(extra.size(), 0)
	assert_eq(sim.get_status(), "game_over")


func test_paddle_input_should_move_horizontally() -> void:
	var config := BreakoutConfig.new()
	var sim := _new_sim(3, config)
	var before := sim.get_paddle_x()
	sim.set_input(1)
	sim.step()
	assert_gt(sim.get_paddle_x(), before)
	assert_almost_eq(sim.get_paddle_x() - before, config.paddle_speed * FixedTick.SEC, 0.001)


func _new_sim(seed_value: int, config: BreakoutConfig) -> BreakoutSim:
	return BreakoutSim.new(config, SeededRng.new(seed_value))


func _run_until_status(sim: BreakoutSim, status: String) -> void:
	var guard := 0
	while sim.get_status() != status and guard < 180:
		sim.step()
		guard += 1
	assert_eq(sim.get_status(), status)


func _event_has_type(events: Array, type_name: String) -> bool:
	for event in events:
		if typeof(event) != TYPE_DICTIONARY:
			continue
		if str(event.get("type", "")) == type_name:
			return true
	return false
