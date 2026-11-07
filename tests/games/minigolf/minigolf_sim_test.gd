extends "res://addons/gut/test.gd"


func test_fairway_park_should_have_nine_holes() -> void:
	var holes := CourseCatalog.build_fairway_park()
	assert_eq(holes.size(), 9)
	assert_eq(holes[0].par, 2)
	assert_eq(holes[8].par, 5)


func test_stroke_should_increment_and_return_to_aim_when_miss() -> void:
	var sim := _new_sim(1, 0, 5)
	# Aim away from cup with tiny power so we stop without sinking.
	sim.set_aim(Vector2(1, 0))
	sim.set_power(0.12)
	sim.stroke()
	sim.resolve_stroke()
	if not sim.get_ball().sunk:
		assert_eq(sim.get_phase(), MinigolfSim.PHASE_AIM)
		assert_eq(sim.get_ball().strokes, 1)


func test_concede_should_cap_strokes_and_finish_hole() -> void:
	var sim := _new_sim(1, 0, 6)
	var events := sim.concede_hole()
	assert_true(_has_type(events, "sunk"))
	assert_true(_has_type(events, "hole_complete"))
	assert_eq(sim.get_phase(), MinigolfSim.PHASE_HOLE_RESULT)
	assert_eq(sim.get_player(0).hole_strokes[0], sim.get_config().max_strokes_for_par(sim.get_hole().par))


func test_advance_should_complete_course_after_nine_holes() -> void:
	var sim := _new_sim(1, 0, 7)
	for hole_i in 9:
		assert_eq(sim.get_hole_index(), hole_i)
		var events := sim.concede_hole()
		assert_true(_has_type(events, "hole_complete"))
		events = sim.advance_after_hole()
		if hole_i < 8:
			assert_eq(sim.get_phase(), MinigolfSim.PHASE_AIM)
		else:
			assert_true(_has_type(events, "course_complete"))
			assert_eq(sim.get_phase(), MinigolfSim.PHASE_COURSE_OVER)
			assert_eq(sim.get_winner(), 0)


func test_per_hole_hotseat_should_rotate_until_all_finish() -> void:
	var sim := _new_sim(2, 0, 8)
	sim.concede_hole()
	assert_eq(sim.get_current_player(), 1)
	assert_eq(sim.get_phase(), MinigolfSim.PHASE_AIM)
	sim.concede_hole()
	assert_eq(sim.get_phase(), MinigolfSim.PHASE_HOLE_RESULT)


func _new_sim(players: int, bot_mask: int, seed_value: int) -> MinigolfSim:
	var sim := MinigolfSim.new(MinigolfConfig.new(), SeededRng.new(seed_value))
	sim.setup(players, bot_mask, CourseCatalog.FAIRWAY_PARK, seed_value)
	return sim


func _has_type(events: Array, type_name: String) -> bool:
	for event in events:
		if typeof(event) == TYPE_DICTIONARY and str(event.get("type", "")) == type_name:
			return true
	return false
