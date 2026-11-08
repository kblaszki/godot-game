extends GutTest


func test_stars_from_lives_thresholds() -> void:
	assert_eq(GridwardProgress.stars_from_lives(15), 3)
	assert_eq(GridwardProgress.stars_from_lives(14), 2)
	assert_eq(GridwardProgress.stars_from_lives(8), 2)
	assert_eq(GridwardProgress.stars_from_lives(7), 1)
	assert_eq(GridwardProgress.stars_from_lives(1), 1)
	assert_eq(GridwardProgress.stars_from_lives(0), 0)
	assert_eq(GridwardProgress.stars_from_lives(12, 12, 6), 3)
	assert_eq(GridwardProgress.stars_from_lives(10, 12, 6), 2)
	assert_eq(GridwardProgress.stars_from_lives(6, 12, 6), 2)
	assert_eq(GridwardProgress.stars_from_lives(5, 12, 6), 1)
	assert_eq(GridwardCatalog.star_thresholds(GridwardCatalog.CITADEL), Vector2i(15, 8))
	assert_eq(GridwardCatalog.star_thresholds(GridwardCatalog.MEADOW), Vector2i(15, 8))


func test_citadel_locked_until_bastion_cleared() -> void:
	var progress := GridwardProgress.new()
	assert_true(progress.is_unlocked(GridwardCatalog.MEADOW))
	assert_false(progress.is_unlocked(GridwardCatalog.BEND))
	assert_false(progress.is_unlocked(GridwardCatalog.CITADEL))
	assert_false(progress.is_unlocked(&"nowhere"))

	progress.record_victory(GridwardCatalog.MEADOW, GridwardConfig.DIFF_EASY, 1)
	assert_eq(progress.stars_for(GridwardCatalog.MEADOW, GridwardConfig.DIFF_EASY), 1)
	assert_true(progress.is_unlocked(GridwardCatalog.BEND))
	assert_false(progress.is_unlocked(GridwardCatalog.SKYREACH))
	assert_false(progress.is_unlocked(GridwardCatalog.CITADEL))

	progress.record_victory(GridwardCatalog.BEND, GridwardConfig.DIFF_NORMAL, 20)
	progress.record_victory(GridwardCatalog.SKYREACH, GridwardConfig.DIFF_HARD, 8)
	assert_eq(progress.stars_for(GridwardCatalog.SKYREACH, GridwardConfig.DIFF_HARD), 2)
	assert_true(progress.is_unlocked(GridwardCatalog.BASTION))
	assert_false(progress.is_unlocked(GridwardCatalog.CITADEL))

	progress.record_victory(GridwardCatalog.BASTION, GridwardConfig.DIFF_NORMAL, 7)
	assert_eq(progress.stars_for(GridwardCatalog.BASTION, GridwardConfig.DIFF_NORMAL), 1)
	assert_true(progress.is_unlocked(GridwardCatalog.CITADEL))


func test_difficulty_should_scale_starting_gold_and_spawn_hp() -> void:
	assert_eq(GridwardConfig.scaled_gold(120, GridwardConfig.EASY_GOLD), 138)
	assert_eq(GridwardConfig.scaled_gold(120, GridwardConfig.NORMAL_GOLD), 120)
	assert_eq(GridwardConfig.scaled_gold(120, GridwardConfig.HARD_GOLD), 108)
	var easy := GridwardConfig.for_difficulty(GridwardConfig.DIFF_EASY)
	var hard := GridwardConfig.for_difficulty(GridwardConfig.DIFF_HARD)
	var normal := GridwardConfig.for_difficulty(&"nightmare")
	assert_almost_eq(easy.difficulty_hp, GridwardConfig.EASY_HP, 0.0001)
	assert_almost_eq(easy.difficulty_gold, GridwardConfig.EASY_GOLD, 0.0001)
	assert_almost_eq(hard.difficulty_hp, GridwardConfig.HARD_HP, 0.0001)
	assert_almost_eq(hard.difficulty_gold, GridwardConfig.HARD_GOLD, 0.0001)
	assert_almost_eq(normal.difficulty_hp, GridwardConfig.NORMAL_HP, 0.0001)
	assert_almost_eq(easy.hp_scale, 1.12, 0.0001)

	var map := GridwardCatalog.build_meadow()
	map.starting_gold = GridwardConfig.scaled_gold(map.starting_gold, hard.difficulty_gold)
	var sim := GridwardSim.new(map, GridwardCatalog.new(), 1)
	sim._config = hard
	assert_eq(sim.get_gold(), 108)
	assert_true(sim.start_wave())
	sim.step()
	var enemy := sim.get_enemies()[0] as EnemyState
	var expected := GridwardSim.scaled_enemy_hp(40, 0, hard.hp_scale, hard.difficulty_hp)
	assert_eq(expected, 50)
	assert_eq(enemy.hp, expected)
	assert_eq(enemy.enemy_id, &"grunt")


func test_campaign_maps_should_teach_one_idea() -> void:
	assert_eq(GridwardCatalog.MAP_IDS.size(), 5)
	assert_eq(GridwardCatalog.MAP_IDS[0], GridwardCatalog.MEADOW)
	assert_eq(GridwardCatalog.MAP_IDS[1], GridwardCatalog.BEND)
	assert_eq(GridwardCatalog.MAP_IDS[2], GridwardCatalog.SKYREACH)
	assert_eq(GridwardCatalog.MAP_IDS[3], GridwardCatalog.BASTION)
	assert_eq(GridwardCatalog.MAP_IDS[4], GridwardCatalog.CITADEL)
	assert_null(GridwardCatalog.build_map(&"void"))

	var meadow := GridwardCatalog.build_map(GridwardCatalog.MEADOW)
	assert_eq(meadow.id, GridwardCatalog.MEADOW)
	assert_eq(meadow.waves.size(), 10)
	assert_eq(meadow.starting_gold, 120)

	var bend := GridwardCatalog.build_bend()
	_assert_board(bend, GridwardCatalog.BEND, 150, 12)
	_assert_towers(bend, [&"bolt", &"mortar"])
	_assert_enemies(bend, [&"grunt", &"runner", &"swarm"])
	assert_true(_has_pack(bend))
	assert_lte(GridwardCatalog.tower(&"mortar").cost, bend.starting_gold)

	var sky := GridwardCatalog.build_skyreach()
	_assert_board(sky, GridwardCatalog.SKYREACH, 180, 12)
	_assert_towers(sky, [&"bolt", &"mortar", &"flak"])
	_assert_enemies(sky, [&"grunt", &"runner", &"swarm", &"flyer"])
	assert_true(_has_enemy(sky, &"flyer"))
	assert_lte(GridwardCatalog.tower(&"flak").cost, sky.starting_gold)

	var bastion := GridwardCatalog.build_bastion()
	_assert_board(bastion, GridwardCatalog.BASTION, 200, 14)
	_assert_towers(bastion, [&"bolt", &"mortar", &"frost", &"flak"])
	_assert_enemies(bastion, [&"grunt", &"runner", &"swarm", &"flyer", &"tank"])
	assert_true(_has_enemy(bastion, &"tank"))
	assert_true(_has_enemy(bastion, &"flyer"))
	assert_lte(GridwardCatalog.tower(&"frost").cost, bastion.starting_gold)

	var citadel := GridwardCatalog.build_citadel()
	_assert_board(citadel, GridwardCatalog.CITADEL, 240, 15)
	_assert_towers(citadel, [&"bolt", &"mortar", &"frost", &"flak", &"beam"])
	_assert_enemies(citadel, GridwardCatalog.ENEMY_IDS)
	assert_true(_has_enemy(citadel, &"boss"))
	assert_true(_has_enemy(citadel, &"tank"))
	assert_true(_has_enemy(citadel, &"flyer"))
	assert_lte(GridwardCatalog.tower(&"beam").cost, citadel.starting_gold)


func _assert_board(map: MapDef, id: StringName, gold: int, waves: int) -> void:
	assert_eq(map.id, id)
	assert_eq(map.width, 16)
	assert_eq(map.height, 10)
	assert_eq(map.starting_lives, 20)
	assert_eq(map.starting_gold, gold)
	assert_eq(map.waves.size(), waves)
	assert_gt(map.waypoints.size(), 1)
	assert_eq(int(map.waypoints[0].x), 0)
	assert_eq(int(map.waypoints[map.waypoints.size() - 1].x), map.width - 1)
	var turns := 0
	var previous := Vector2i.ZERO
	for i in map.waypoints.size():
		var cell := Vector2i(roundi(map.waypoints[i].x), roundi(map.waypoints[i].y))
		assert_true(map.in_bounds(cell), "%s waypoint %s" % [id, cell])
		if i == 0:
			continue
		var before := Vector2i(roundi(map.waypoints[i - 1].x), roundi(map.waypoints[i - 1].y))
		var delta := cell - before
		assert_true(delta.x == 0 or delta.y == 0)
		assert_ne(delta, Vector2i.ZERO)
		if i > 1 and delta != previous:
			turns += 1
		previous = delta
	assert_gt(turns, 0)
	assert_eq(map.buildable.size(), map.width * map.height)
	var on_path := {}
	for cell in map.path_cells():
		assert_true(map.in_bounds(cell))
		on_path[cell] = true
	var buildable_count := 0
	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y)
			var mask := int(map.buildable[map.cell_index(cell)])
			if on_path.has(cell):
				assert_eq(mask, 0)
			else:
				assert_eq(mask, 1)
				buildable_count += 1
	assert_gt(buildable_count, 0)


func _assert_towers(map: MapDef, ids) -> void:
	assert_eq(map.unlocked_towers.size(), ids.size())
	for i in ids.size():
		assert_eq(map.unlocked_towers[i], ids[i])
		assert_not_null(GridwardCatalog.tower(ids[i]))


func _assert_enemies(map: MapDef, allowed) -> void:
	var seen := {}
	for wave in map.waves:
		assert_gt(wave.entries.size(), 0)
		for entry in wave.entries:
			var row: Dictionary = entry
			var enemy_id: StringName = row["enemy_id"]
			assert_true(allowed.has(enemy_id), "%s spawned %s" % [map.id, enemy_id])
			assert_not_null(GridwardCatalog.enemy(enemy_id))
			assert_gt(int(row["count"]), 0)
			assert_gt(int(row["spacing_ticks"]), 0)
			assert_gte(int(row["delay_ticks"]), 0)
			seen[enemy_id] = true
	assert_gt(seen.size(), 0)


func _has_enemy(map: MapDef, enemy_id: StringName) -> bool:
	for wave in map.waves:
		for entry in wave.entries:
			if entry["enemy_id"] == enemy_id:
				return true
	return false


func _has_pack(map: MapDef) -> bool:
	for wave in map.waves:
		for entry in wave.entries:
			var row: Dictionary = entry
			if int(row["count"]) >= 6 and int(row["spacing_ticks"]) <= 24:
				return true
	return false
