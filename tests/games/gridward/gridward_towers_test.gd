extends GutTest


func test_place_on_path_should_fail() -> void:
	var sim := _meadow()
	assert_eq(sim.place_tower(Vector2i(0, 1), &"bolt"), -1)
	assert_eq(sim.place_tower(Vector2i(12, 4), &"bolt"), -1)
	assert_eq(sim.get_gold(), 120)
	assert_eq(sim.get_towers().size(), 0)
	assert_eq(sim.place_tower(Vector2i(0, 0), &"mortar"), -1)
	assert_eq(sim.get_gold(), 120)


func test_place_should_spend_gold() -> void:
	var sim := _meadow()
	var first := sim.place_tower(Vector2i(0, 0), &"bolt")
	assert_eq(first, 0)
	assert_eq(sim.get_gold(), 70)
	var second := sim.place_tower(Vector2i(1, 0), &"bolt")
	assert_eq(second, 1)
	assert_eq(sim.get_gold(), 20)
	assert_eq(sim.place_tower(Vector2i(2, 0), &"bolt"), -1)
	assert_eq(sim.place_tower(Vector2i(0, 0), &"bolt"), -1)
	assert_eq(sim.get_gold(), 20)
	assert_eq(sim.get_towers().size(), 2)


func test_bolt_should_damage_first_in_range() -> void:
	var sim := _two_grunts()
	_approach(sim)
	var tower_id := sim.place_tower(Vector2i(0, 1), &"bolt")
	assert_gte(tower_id, 0)
	sim.step()
	assert_eq(sim.get_enemies().size(), 2)
	assert_eq(_hp(sim, 0), _grunt_hp() - _bolt_damage())
	assert_eq(_hp(sim, 1), _grunt_hp())


func test_targeting_closest_should_pick_nearest() -> void:
	var sim := _two_grunts()
	_approach(sim)
	var tower_id := sim.place_tower(Vector2i(0, 1), &"bolt")
	sim.set_targeting(tower_id, &"closest")
	sim.step()
	assert_eq(_hp(sim, 1), _grunt_hp() - _bolt_damage())
	assert_eq(_hp(sim, 0), _grunt_hp())


func test_targeting_last_should_pick_trailing() -> void:
	var sim := _two_grunts()
	_approach(sim)
	var tower_id := sim.place_tower(Vector2i(2, 1), &"bolt")
	sim.set_targeting(tower_id, &"last")
	sim.step()
	assert_eq(_hp(sim, 1), _grunt_hp() - _bolt_damage())
	assert_eq(_hp(sim, 0), _grunt_hp())


func test_targeting_strongest_should_pick_highest_hp() -> void:
	var sim := _grunt_and_runner()
	var tower_id := sim.place_tower(Vector2i(0, 1), &"bolt")
	sim.set_targeting(tower_id, &"strongest")
	assert_true(sim.start_wave())
	sim.step()
	assert_eq(_hp(sim, 0), _grunt_hp() - _bolt_damage())
	assert_eq(_hp(sim, 1), GridwardCatalog.enemy(&"runner").hp)


func test_targeting_weakest_should_pick_lowest_hp() -> void:
	var sim := _grunt_and_runner()
	var tower_id := sim.place_tower(Vector2i(0, 1), &"bolt")
	sim.set_targeting(tower_id, &"weakest")
	assert_true(sim.start_wave())
	sim.step()
	assert_eq(_hp(sim, 0), _grunt_hp())
	assert_eq(_hp(sim, 1), GridwardCatalog.enemy(&"runner").hp - _bolt_damage())


func test_targeting_tie_should_pick_lowest_id() -> void:
	var map := _lane([&"bolt"])
	_add_wave(map, [[&"grunt", 2, 0, 0]])
	var sim := GridwardSim.new(map, GridwardCatalog.new(), 4)
	var tower_id := sim.place_tower(Vector2i(0, 1), &"bolt")
	sim.set_targeting(tower_id, &"closest")
	assert_true(sim.start_wave())
	sim.step()
	assert_eq(_hp(sim, 0), _grunt_hp() - _bolt_damage())
	assert_eq(_hp(sim, 1), _grunt_hp())


func test_mortar_splash_should_hit_neighbors() -> void:
	var map := _lane([&"mortar"])
	_add_wave(map, [[&"grunt", 3, 5, 0]])
	var sim := GridwardSim.new(map, GridwardCatalog.new(), 5)
	assert_true(sim.start_wave())
	for _i in 11:
		sim.step()
	assert_eq(sim.get_enemies().size(), 3)
	var tower_id := sim.place_tower(Vector2i(0, 1), &"mortar")
	assert_gte(tower_id, 0)
	sim.step()
	for enemy in sim.get_enemies():
		var body: EnemyState = enemy
		assert_eq(body.hp, _grunt_hp())
	assert_eq(sim.get_projectiles().size(), 1)
	var guard := 0
	while sim.get_projectiles().size() > 0 and guard < 120:
		sim.step()
		guard += 1
	assert_eq(sim.get_projectiles().size(), 0)
	assert_gt(guard, 0)
	assert_eq(sim.get_enemies().size(), 3)
	for enemy in sim.get_enemies():
		var body: EnemyState = enemy
		assert_eq(body.hp, _grunt_hp() - GridwardCatalog.tower(&"mortar").damage)


func test_sell_should_refund_seventy_percent() -> void:
	var sim := _meadow()
	var tower_id := sim.place_tower(Vector2i(0, 0), &"bolt")
	assert_eq(sim.get_gold(), 70)
	assert_true(sim.sell_tower(tower_id))
	assert_eq(sim.get_gold(), 105)
	assert_eq(sim.get_towers().size(), 0)
	assert_false(sim.sell_tower(tower_id))
	assert_eq(sim.get_gold(), 105)
	assert_eq(sim.place_tower(Vector2i(0, 0), &"bolt"), 1)


func test_upgrade_should_spend_curve_and_scale_damage() -> void:
	var map := _lane([&"bolt"])
	map.starting_gold = 200
	var sim := GridwardSim.new(map, GridwardCatalog.new(), 6)
	var tower_id := sim.place_tower(Vector2i(0, 1), &"bolt")
	assert_true(sim.upgrade_tower(tower_id))
	assert_eq(sim.get_gold(), 200 - 50 - 38)
	var tower: TowerState = sim.get_towers()[0]
	assert_eq(tower.tier, 1)
	assert_eq(tower.damage, 16)
	assert_almost_eq(tower.range, 2.7, 0.0001)
	assert_true(sim.upgrade_tower(tower_id))
	assert_eq(sim.get_gold(), 200 - 50 - 38 - 58)
	assert_eq(tower.tier, 2)
	assert_eq(tower.damage, 22)
	assert_almost_eq(tower.range, 2.916, 0.0001)
	assert_false(sim.upgrade_tower(tower_id))
	assert_eq(sim.get_gold(), 54)
	assert_true(sim.sell_tower(tower_id))
	assert_eq(sim.get_gold(), 54 + 102)


func _meadow() -> GridwardSim:
	return GridwardSim.new(GridwardCatalog.build_meadow(), GridwardCatalog.new(), 1)


func _two_grunts() -> GridwardSim:
	var map := _lane([&"bolt"])
	_add_wave(map, [[&"grunt", 2, 100, 0]])
	return GridwardSim.new(map, GridwardCatalog.new(), 2)


func _grunt_and_runner() -> GridwardSim:
	var map := _lane([&"bolt"])
	_add_wave(map, [[&"grunt", 1, 1, 0], [&"runner", 1, 1, 0]])
	return GridwardSim.new(map, GridwardCatalog.new(), 3)


func _approach(sim: GridwardSim) -> void:
	assert_true(sim.start_wave())
	for _i in 100:
		sim.step()
	assert_eq(sim.get_enemies().size(), 1)


func _lane(unlocked: Array[StringName]) -> MapDef:
	var map := MapDef.new()
	map.id = &"lane"
	map.width = 12
	map.height = 4
	map.starting_gold = 200
	map.starting_lives = 20
	map.waypoints = PackedVector2Array([Vector2(0, 0), Vector2(10, 0)])
	map.unlocked_towers = unlocked
	map.apply_buildable_off_path()
	return map


func _add_wave(map: MapDef, rows: Array) -> void:
	var wave := WaveDef.new()
	for row in rows:
		wave.entries.append({
			"enemy_id": row[0],
			"count": row[1],
			"spacing_ticks": row[2],
			"delay_ticks": row[3],
		})
	map.waves.append(wave)


func _hp(sim: GridwardSim, id: int) -> int:
	for enemy in sim.get_enemies():
		var body: EnemyState = enemy
		if body.id == id:
			return body.hp
	return -1


func _grunt_hp() -> int:
	return GridwardCatalog.enemy(&"grunt").hp


func _bolt_damage() -> int:
	return GridwardCatalog.tower(&"bolt").damage
