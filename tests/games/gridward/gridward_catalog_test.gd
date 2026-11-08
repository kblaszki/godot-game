extends GutTest

func test_meadow_path_cells_should_stay_in_bounds() -> void:
	var map := GridwardCatalog.build_meadow()
	assert_eq(map.id, &"meadow")
	assert_eq(GridwardCatalog.MEADOW, &"meadow")
	assert_eq(map.width, 16)
	assert_eq(map.height, 10)
	assert_eq(map.starting_gold, 120)
	assert_eq(map.starting_lives, 20)
	var expected := PackedVector2Array([
		Vector2(0, 1),
		Vector2(12, 1),
		Vector2(12, 4),
		Vector2(3, 4),
		Vector2(3, 7),
		Vector2(15, 7),
	])
	assert_eq(map.waypoints.size(), expected.size())
	var horizontal: Array[int] = []
	for i in expected.size():
		assert_eq(map.waypoints[i], expected[i])
		var cell := Vector2i(roundi(expected[i].x), roundi(expected[i].y))
		assert_true(map.in_bounds(cell))
		if i == 0:
			continue
		var previous := Vector2i(roundi(expected[i - 1].x), roundi(expected[i - 1].y))
		var dx := cell.x - previous.x
		var dy := cell.y - previous.y
		assert_true(dx == 0 or dy == 0)
		assert_true(dx != 0 or dy != 0)
		if dx != 0:
			horizontal.append(signi(dx))
	assert_eq(int(expected[0].x), 0)
	assert_eq(int(expected[expected.size() - 1].x), map.width - 1)
	assert_eq(horizontal.size(), 3)
	for i in range(1, horizontal.size()):
		assert_ne(horizontal[i], horizontal[i - 1])
	var cells := map.path_cells()
	assert_gt(cells.size(), expected.size())
	for cell in cells:
		assert_true(map.in_bounds(cell))
	for i in expected.size():
		var waypoint := Vector2i(roundi(expected[i].x), roundi(expected[i].y))
		assert_true(cells.has(waypoint))

func test_buildable_should_not_overlap_path() -> void:
	var map := GridwardCatalog.build_meadow()
	assert_eq(map.buildable.size(), map.width * map.height)
	var on_path := {}
	for cell in map.path_cells():
		on_path[cell] = true
	var buildable_count := 0
	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y)
			var mask := int(map.buildable[map.cell_index(cell)])
			assert_true(mask == 0 or mask == 1)
			if on_path.has(cell):
				assert_eq(mask, 0)
			else:
				assert_eq(mask, 1)
				buildable_count += 1
	assert_gt(on_path.size(), 0)
	assert_gt(buildable_count, 0)

func test_waves_should_reference_known_enemies() -> void:
	var map := GridwardCatalog.build_meadow()
	assert_eq(map.waves.size(), 10)
	var seen := {}
	for wave_index in map.waves.size():
		var wave: WaveDef = map.waves[wave_index]
		assert_gt(wave.entries.size(), 0)
		for entry in wave.entries:
			var row: Dictionary = entry
			var enemy_id: StringName = row["enemy_id"]
			assert_true(enemy_id == &"grunt" or enemy_id == &"runner")
			var enemy := GridwardCatalog.enemy(enemy_id)
			assert_not_null(enemy)
			assert_eq(enemy.id, enemy_id)
			assert_eq(typeof(row["count"]), TYPE_INT)
			assert_eq(typeof(row["spacing_ticks"]), TYPE_INT)
			assert_eq(typeof(row["delay_ticks"]), TYPE_INT)
			assert_gt(int(row["count"]), 0)
			assert_gt(int(row["spacing_ticks"]), 0)
			assert_gte(int(row["delay_ticks"]), 0)
			seen[enemy_id] = true
	assert_true(seen.has(&"grunt"))
	assert_true(seen.has(&"runner"))
	assert_eq(seen.size(), 2)

func test_tower_and_enemy_tables_should_match_spec_ids() -> void:
	var enemy_ids: Array[StringName] = [
		&"grunt", &"runner", &"tank", &"swarm", &"flyer", &"boss",
	]
	var tower_ids: Array[StringName] = [
		&"bolt", &"mortar", &"frost", &"flak", &"beam",
	]
	assert_eq(GridwardCatalog.ENEMY_IDS, enemy_ids)
	assert_eq(GridwardCatalog.TOWER_IDS, tower_ids)
	assert_null(GridwardCatalog.enemy(&"wisp"))
	assert_null(GridwardCatalog.tower(&"laser"))

	_assert_enemy(&"grunt", 40, 1.2, 8, 0, false, false, false)
	_assert_enemy(&"runner", 24, 2.4, 10, 0, false, false, false)
	_assert_enemy(&"tank", 120, 0.7, 18, 4, false, false, false)
	_assert_enemy(&"swarm", 12, 1.8, 3, 0, false, true, false)
	_assert_enemy(&"flyer", 36, 1.6, 14, 0, true, false, false)
	_assert_enemy(&"boss", 800, 0.55, 100, 6, false, false, true)

	_assert_tower(&"bolt", 50, 2.5, 30, 12, &"hitscan", 0.0, 0.0, 0, false, true, 0)
	_assert_tower(&"mortar", 80, 3.5, 75, 28, &"projectile", 1.2, 0.0, 0, false, true, 0)
	_assert_tower(&"frost", 70, 2.2, 45, 4, &"hitscan", 0.0, 0.35, 90, false, true, 0)
	_assert_tower(&"flak", 90, 3.0, 24, 10, &"hitscan", 0.0, 0.0, 0, true, false, 0)
	_assert_tower(&"beam", 110, 2.8, 6, 3, &"continuous", 0.0, 0.0, 0, false, true, 12)

	var map := GridwardCatalog.build_meadow()
	assert_eq(map.unlocked_towers.size(), 1)
	assert_eq(map.unlocked_towers[0], &"bolt")

	var config := GridwardConfig.new()
	assert_almost_eq(config.hp_scale, 1.12, 0.0001)
	assert_almost_eq(config.sell_refund, 0.70, 0.0001)
	assert_eq(config.wave_clear_bonus_base, 25)
	assert_eq(config.wave_clear_bonus_per_index, 5)
	assert_eq(config.early_call_ticks_per_gold, 30)
	assert_eq(config.early_call_gold_cap, 40)
	assert_almost_eq(config.upgrade_cost_factor, 0.75, 0.0001)
	assert_almost_eq(config.upgrade_cost_growth, 1.55, 0.0001)
	assert_almost_eq(config.tier_damage_scale, 1.35, 0.0001)
	assert_almost_eq(config.tier_range_scale, 1.08, 0.0001)
	assert_eq(config.max_tier, 2)
	assert_eq(config.min_damage, 1)
	assert_almost_eq(config.slow_cap, 0.60, 0.0001)
	assert_eq(config.burn_max_stacks, 5)
	assert_eq(config.burn_damage_per_stack, 1)
	assert_eq(config.spawn_jitter_ticks, 0)
	assert_almost_eq(config.difficulty_hp, GridwardConfig.NORMAL_HP, 0.0001)
	assert_almost_eq(config.difficulty_gold, GridwardConfig.NORMAL_GOLD, 0.0001)
	assert_almost_eq(GridwardConfig.EASY_HP, 0.85, 0.0001)
	assert_almost_eq(GridwardConfig.EASY_GOLD, 1.15, 0.0001)
	assert_almost_eq(GridwardConfig.HARD_HP, 1.25, 0.0001)
	assert_almost_eq(GridwardConfig.HARD_GOLD, 0.9, 0.0001)

func _assert_enemy(
	id: StringName,
	hp: int,
	speed: float,
	bounty: int,
	armor: int,
	is_air: bool,
	is_group: bool,
	is_boss: bool
) -> void:
	var enemy := GridwardCatalog.enemy(id)
	assert_not_null(enemy)
	assert_eq(enemy.id, id)
	assert_eq(enemy.hp, hp)
	assert_almost_eq(enemy.speed, speed, 0.0001)
	assert_eq(enemy.bounty, bounty)
	assert_eq(enemy.armor, armor)
	assert_eq(enemy.is_air, is_air)
	assert_eq(enemy.is_group, is_group)
	assert_eq(enemy.is_boss, is_boss)

func _assert_tower(
	id: StringName,
	cost: int,
	tower_range: float,
	cooldown_ticks: int,
	damage: int,
	kind: StringName,
	splash_radius: float,
	slow_factor: float,
	slow_ticks: int,
	anti_air: bool,
	ground_only: bool,
	ramp_damage: int
) -> void:
	var built := GridwardCatalog.tower(id)
	assert_not_null(built)
	assert_eq(built.id, id)
	assert_eq(built.cost, cost)
	assert_almost_eq(built.range, tower_range, 0.0001)
	assert_eq(built.cooldown_ticks, cooldown_ticks)
	assert_eq(built.damage, damage)
	assert_eq(built.kind, kind)
	assert_almost_eq(built.splash_radius, splash_radius, 0.0001)
	assert_almost_eq(built.slow_factor, slow_factor, 0.0001)
	assert_eq(built.slow_ticks, slow_ticks)
	assert_eq(built.anti_air, anti_air)
	assert_eq(built.ground_only, ground_only)
	assert_eq(built.ramp_damage, ramp_damage)
