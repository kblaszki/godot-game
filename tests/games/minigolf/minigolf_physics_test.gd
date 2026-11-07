extends "res://addons/gut/test.gd"


func test_friction_should_stop_ball() -> void:
	var sim := _new_sim(1, 0, 1)
	sim.set_aim(Vector2(0, 1))
	sim.set_power(0.25)
	sim.stroke()
	var events := sim.resolve_stroke()
	assert_true(_has_type(events, "stopped") or _has_type(events, "sunk"))
	assert_lt(sim.get_ball().speed(), sim.get_config().stop_eps + 0.001)


func test_wall_bounce_should_reflect_velocity() -> void:
	var sim := _new_sim(1, 0, 2)
	# Aim hard into the left wall of hole 1.
	sim.get_ball().pos = Vector2(-0.9, 1.0)
	sim.set_aim(Vector2(-1, 0))
	sim.set_power(1.0)
	sim.stroke()
	var events := sim.resolve_stroke()
	assert_true(_has_type(events, "bounced") or sim.get_ball().pos.x > -1.2)


func test_sink_when_slow_near_cup() -> void:
	var sim := _new_sim(1, 0, 3)
	var cup := sim.get_hole().cup_xz()
	sim.get_ball().pos = cup + Vector2(0.02, 0)
	sim.get_ball().vel = Vector2(0.1, 0)
	sim._phase = MinigolfSim.PHASE_MOVING
	sim._tick_count = 0
	var events := sim.resolve_stroke()
	assert_true(_has_type(events, "sunk"))
	assert_true(sim.get_ball().sunk)


func test_oob_should_reset_to_last_fairway() -> void:
	var sim := _new_sim(1, 0, 4)
	sim.get_ball().pos = Vector2(0, 1)
	sim.get_ball().last_fairway = Vector2(0, 1)
	sim.get_ball().vel = Vector2(0, 20)
	sim._phase = MinigolfSim.PHASE_MOVING
	sim._tick_count = 0
	# Force position outside after a tick by teleporting then integrating check.
	sim.get_ball().pos = Vector2(50, 50)
	var events: Array = []
	# Manually trigger OOB path via tick with pos already OOB.
	sim.get_ball().vel = Vector2.ZERO
	events.append_array(sim.tick(1))
	# If still moving with zero vel it stops; set OOB and call integrate path:
	sim._phase = MinigolfSim.PHASE_MOVING
	sim.get_ball().pos = Vector2(99, 99)
	sim.get_ball().vel = Vector2(1, 0)
	events = sim.tick(1)
	assert_true(_has_type(events, "oob_reset"))
	assert_eq(sim.get_ball().pos, Vector2(0, 1))


func test_same_seed_strokes_should_match() -> void:
	var left := _new_sim(1, 0, 11)
	var right := _new_sim(1, 0, 11)
	left.set_aim(Vector2(0.1, 1).normalized())
	right.set_aim(Vector2(0.1, 1).normalized())
	left.set_power(0.55)
	right.set_power(0.55)
	assert_eq(left.stroke(), right.stroke())
	assert_eq(left.resolve_stroke(), right.resolve_stroke())
	assert_eq(left.get_ball().pos, right.get_ball().pos)
	assert_eq(left.get_ball().strokes, right.get_ball().strokes)


func _new_sim(players: int, bot_mask: int, seed_value: int) -> MinigolfSim:
	var sim := MinigolfSim.new(MinigolfConfig.new(), SeededRng.new(seed_value))
	sim.setup(players, bot_mask, CourseCatalog.FAIRWAY_PARK, seed_value)
	return sim


func _has_type(events: Array, type_name: String) -> bool:
	for event in events:
		if typeof(event) == TYPE_DICTIONARY and str(event.get("type", "")) == type_name:
			return true
	return false
