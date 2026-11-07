extends "res://addons/gut/test.gd"


func test_bot_should_finish_hole_one() -> void:
	var sim := _new_sim(1, 1, 20)
	var guard := 0
	while sim.get_phase() != MinigolfSim.PHASE_HOLE_RESULT and guard < 40:
		sim.bot_act()
		guard += 1
	assert_eq(sim.get_phase(), MinigolfSim.PHASE_HOLE_RESULT)
	assert_gt(sim.get_player(0).hole_strokes[0], 0)


func test_two_bots_same_seed_should_match() -> void:
	var left := _new_sim(2, 3, 42)
	var right := _new_sim(2, 3, 42)
	for _i in 80:
		if left.get_phase() == MinigolfSim.PHASE_COURSE_OVER:
			break
		assert_eq(left.bot_act(), right.bot_act())
	assert_eq(left.get_phase(), right.get_phase())
	assert_eq(left.get_player(0).total(), right.get_player(0).total())
	assert_eq(left.get_player(1).total(), right.get_player(1).total())


func _new_sim(players: int, bot_mask: int, seed_value: int) -> MinigolfSim:
	var sim := MinigolfSim.new(MinigolfConfig.new(), SeededRng.new(seed_value))
	sim.setup(players, bot_mask, CourseCatalog.FAIRWAY_PARK, seed_value)
	return sim
