extends GutTest


func test_same_seed_and_inputs_should_match() -> void:
	var a := _make_sim(7)
	var b := _make_sim(7)
	var scripted: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 0),
	]
	for i in 40:
		var dir: Vector2i = scripted[i % scripted.size()]
		a.set_input(dir.x, dir.y)
		b.set_input(dir.x, dir.y)
		a.step()
		b.step()
	assert_eq(a.get_score(), b.get_score())
	assert_eq(a.get_status(), b.get_status())
	assert_eq(a.get_food(), b.get_food())
	assert_eq(a.get_segments(), b.get_segments())
	assert_eq(a.get_direction(), b.get_direction())


func test_should_ignore_immediate_reverse() -> void:
	var sim := _make_sim(1)
	# Default dir is +x. Attempt reverse to -x before first move.
	sim.set_input(-1, 0)
	_step_until_move(sim)
	assert_eq(sim.get_direction(), Vector2i(1, 0))
	var head: Vector2i = sim.get_segments()[0]
	assert_eq(head, Vector2i(10, 7) + Vector2i(1, 0))


func test_eating_should_grow_and_score() -> void:
	var config := SnakeConfig.new()
	config.width = 6
	config.height = 4
	config.move_every_ticks = 1
	config.start_length = 1
	# Pick a seed where food spawns one cell to the right of the starting head.
	for p_seed in 64:
		var sim := SnakeSim.new(config, SeededRng.new(p_seed))
		var head: Vector2i = sim.get_segments()[0]
		if sim.get_food() != head + Vector2i(1, 0):
			continue
		var before_len: int = sim.get_segments().size()
		sim.set_input(1, 0)
		var events: Array = sim.step()
		assert_eq(events.size(), 1)
		assert_eq((events[0] as Dictionary).get("type"), "ate")
		assert_eq(sim.get_score(), 1)
		assert_eq(sim.get_segments().size(), before_len + 1)
		return
	fail_test("No seed placed food directly ahead of the head")


func test_wall_collision_should_game_over() -> void:
	var config := SnakeConfig.new()
	config.width = 5
	config.height = 5
	config.move_every_ticks = 1
	config.start_length = 1
	var sim := SnakeSim.new(config, SeededRng.new(1))
	# Head starts at center (2,2), go left until wall.
	sim.set_input(-1, 0)
	var events: Array = []
	for _i in 10:
		events = sim.step()
		if sim.get_status() == "game_over":
			break
	assert_eq(sim.get_status(), "game_over")
	assert_gt(events.size(), 0)
	assert_eq((events[0] as Dictionary).get("type"), "game_over")


func test_self_collision_should_game_over() -> void:
	var config := SnakeConfig.new()
	config.width = 10
	config.height = 10
	config.move_every_ticks = 1
	config.start_length = 5
	var sim := SnakeSim.new(config, SeededRng.new(2))
	# Grow by eating then loop into body — script a box that hits self.
	# Start facing +x with length 5. Turn down, left, up into body.
	var plan: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(1, 0),
		Vector2i(0, 1), Vector2i(0, 1),
		Vector2i(-1, 0), Vector2i(-1, 0),
		Vector2i(0, -1),
	]
	for dir in plan:
		sim.set_input(dir.x, dir.y)
		sim.step()
		if sim.get_status() == "game_over":
			break
	# If still alive, keep turning into self.
	if sim.get_status() != "game_over":
		sim.set_input(1, 0)
		for _i in 5:
			sim.step()
			if sim.get_status() == "game_over":
				break
	assert_eq(sim.get_status(), "game_over")


func _make_sim(p_seed: int) -> SnakeSim:
	var config := SnakeConfig.new()
	config.move_every_ticks = 1
	return SnakeSim.new(config, SeededRng.new(p_seed))


func _step_until_move(sim: SnakeSim) -> void:
	sim.step()
