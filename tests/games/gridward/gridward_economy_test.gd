extends GutTest


func test_kill_should_add_bounty() -> void:
	var sim := GridwardSim.new(_kill_map(), GridwardCatalog.new(), 1)
	assert_eq(sim.place_tower(Vector2i(0, 0), &"bolt"), 0)
	assert_eq(sim.get_gold(), 50)
	assert_false(sim.can_early_call())
	assert_true(sim.start_wave())
	assert_eq(sim.get_gold(), 50)
	var killed := false
	var guard := 0
	while not killed and guard < 400:
		sim.step()
		guard += 1
		for event in sim.drain_events():
			var row: Dictionary = event
			if row["type"] != GridwardEvents.ENEMY_KILLED:
				continue
			killed = true
			assert_eq(row["enemy_id"], &"grunt")
			assert_eq(int(row["bounty"]), 8)
			assert_eq(int(row["gold"]), 58)
	assert_true(killed)
	assert_eq(sim.get_gold(), 58)
	assert_eq(sim.get_phase(), GridwardSim.Phase.WAVE)
	assert_gt(guard, 1)


func test_wave_clear_should_add_bonus() -> void:
	var sim := GridwardSim.new(_leak_map(40), GridwardCatalog.new(), 2)
	assert_true(sim.start_wave())
	assert_eq(sim.get_gold(), 40)
	_run_to_clear(sim)
	assert_eq(sim.get_gold(), 40 + 25)
	assert_eq(sim.get_wave_index(), 0)
	var cleared := sim.drain_events()
	assert_eq(_field(cleared, GridwardEvents.WAVE_CLEARED, "bonus"), 25)
	assert_eq(_field(cleared, GridwardEvents.WAVE_CLEARED, "gold"), 65)
	sim.step()
	assert_eq(sim.get_phase(), GridwardSim.Phase.BUILD)
	var guard := 0
	while sim.can_early_call() and guard < 5000:
		sim.step()
		guard += 1
	assert_false(sim.can_early_call())
	assert_eq(sim.early_call_bonus(), 0)
	assert_true(sim.start_wave())
	assert_eq(sim.get_gold(), 65)
	_run_to_clear(sim)
	assert_eq(sim.get_wave_index(), 1)
	assert_eq(sim.get_gold(), 65 + 25 + 5)


func test_upgrade_cost_should_follow_geometric_curve() -> void:
	var factor := 0.75
	var growth := 1.55
	assert_eq(GridwardSim.upgrade_cost(50, 0, factor, growth), 38)
	assert_eq(GridwardSim.upgrade_cost(50, 1, factor, growth), 58)
	assert_eq(GridwardSim.upgrade_cost(80, 0, factor, growth), 60)
	assert_eq(GridwardSim.upgrade_cost(80, 1, factor, growth), 93)
	assert_eq(GridwardSim.upgrade_cost(70, 0, factor, growth), 53)
	assert_eq(GridwardSim.upgrade_cost(70, 1, factor, growth), 81)
	var config := GridwardConfig.new()
	assert_almost_eq(config.upgrade_cost_factor, factor, 0.0001)
	assert_almost_eq(config.upgrade_cost_growth, growth, 0.0001)
	assert_almost_eq(config.sell_refund, 0.70, 0.0001)
	assert_almost_eq(config.hp_scale, 1.12, 0.0001)
	assert_eq(GridwardSim.scaled_enemy_hp(40, 0, config.hp_scale, config.difficulty_hp), 40)
	assert_eq(GridwardSim.scaled_enemy_hp(40, 1, config.hp_scale, config.difficulty_hp), 45)

	var map := MapDef.new()
	map.id = &"upgrade"
	map.width = 4
	map.height = 4
	map.starting_gold = 500
	map.starting_lives = 5
	map.unlocked_towers = [&"bolt", &"mortar"]
	map.apply_buildable_off_path()
	var sim := GridwardSim.new(map, GridwardCatalog.new(), 3)
	var bolt_id := sim.place_tower(Vector2i(0, 0), &"bolt")
	assert_eq(sim.get_gold(), 450)
	assert_true(sim.upgrade_tower(bolt_id))
	assert_eq(sim.get_gold(), 450 - 38)
	assert_true(sim.upgrade_tower(bolt_id))
	assert_eq(sim.get_gold(), 450 - 38 - 58)
	var before := sim.get_gold()
	var mortar_id := sim.place_tower(Vector2i(1, 0), &"mortar")
	assert_eq(sim.get_gold(), before - 80)
	assert_true(sim.upgrade_tower(mortar_id))
	assert_eq(sim.get_gold(), before - 80 - 60)


func test_early_call_should_grant_capped_bonus() -> void:
	var config := GridwardConfig.new()
	var opening := GridwardSim.new(_leak_map(80), GridwardCatalog.new(), 4)
	assert_false(opening.can_early_call())
	assert_eq(opening.early_call_bonus(), 0)
	assert_true(opening.start_wave())
	assert_eq(opening.get_gold(), 80)
	var started := opening.drain_events()
	assert_eq(_field(started, GridwardEvents.WAVE_STARTED, "early_bonus"), 0)

	var sim := _enter_build_after_clear(5)
	var uncapped := floori(float(config.build_timer_ticks) / float(config.early_call_ticks_per_gold))
	assert_eq(config.build_timer_ticks, 1500)
	assert_gt(uncapped, config.early_call_gold_cap)
	assert_true(sim.can_early_call())
	assert_eq(sim.early_call_bonus(), config.early_call_gold_cap)
	sim.drain_events()
	var before := sim.get_gold()
	assert_true(sim.start_wave())
	assert_eq(sim.get_gold(), before + config.early_call_gold_cap)
	assert_false(sim.can_early_call())
	assert_eq(sim.early_call_bonus(), 0)
	var events := sim.drain_events()
	assert_eq(_field(events, GridwardEvents.WAVE_STARTED, "early_bonus"), config.early_call_gold_cap)


func test_early_call_should_shrink_as_build_ticks_pass() -> void:
	var config := GridwardConfig.new()
	var sim := _enter_build_after_clear(6)
	var steps := int(config.build_timer_ticks / 2)
	for _i in steps:
		sim.step()
	assert_eq(sim.get_phase(), GridwardSim.Phase.BUILD)
	var remaining := config.build_timer_ticks - steps
	var expected := mini(
		floori(float(remaining) / float(config.early_call_ticks_per_gold)),
		config.early_call_gold_cap
	)
	assert_gt(expected, 0)
	assert_lt(expected, config.early_call_gold_cap)
	assert_eq(sim.early_call_bonus(), expected)
	var before := sim.get_gold()
	assert_true(sim.start_wave())
	assert_eq(sim.get_gold(), before + expected)


func _enter_build_after_clear(seed: int) -> GridwardSim:
	var sim := GridwardSim.new(_leak_map(80), GridwardCatalog.new(), seed)
	assert_true(sim.start_wave())
	_run_to_clear(sim)
	sim.step()
	assert_eq(sim.get_phase(), GridwardSim.Phase.BUILD)
	assert_true(sim.can_early_call())
	return sim


func _run_to_clear(sim: GridwardSim) -> void:
	var guard := 0
	while sim.get_phase() == GridwardSim.Phase.WAVE and guard < 800:
		sim.step()
		guard += 1
	assert_eq(sim.get_phase(), GridwardSim.Phase.WAVE_CLEAR)


func _kill_map() -> MapDef:
	var map := MapDef.new()
	map.id = &"bounty"
	map.width = 16
	map.height = 4
	map.starting_gold = 100
	map.starting_lives = 10
	map.waypoints = PackedVector2Array([Vector2(0, 1), Vector2(14, 1)])
	map.unlocked_towers = [&"bolt"]
	map.apply_buildable_off_path()
	var wave := WaveDef.new()
	wave.entries.append({
		"enemy_id": &"grunt",
		"count": 2,
		"spacing_ticks": 400,
		"delay_ticks": 0,
	})
	map.waves.append(wave)
	return map


func _leak_map(gold: int) -> MapDef:
	var map := MapDef.new()
	map.id = &"clear"
	map.width = 6
	map.height = 3
	map.starting_gold = gold
	map.starting_lives = 8
	map.waypoints = PackedVector2Array([Vector2(0, 1), Vector2(2, 1)])
	for _i in 2:
		var wave := WaveDef.new()
		wave.entries.append({
			"enemy_id": &"grunt",
			"count": 1,
			"spacing_ticks": 10,
			"delay_ticks": 0,
		})
		map.waves.append(wave)
	return map


func _field(events: Array, event_type: StringName, key: String) -> int:
	for event in events:
		var row: Dictionary = event
		if row["type"] == event_type:
			return int(row[key])
	return -1
