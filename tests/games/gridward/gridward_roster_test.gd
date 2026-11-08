extends GutTest


func test_armor_should_reduce_damage_to_minimum_one() -> void:
	var tank_hp := GridwardCatalog.enemy(&"tank").hp
	var bolt := GridwardCatalog.tower(&"bolt")
	var tank := GridwardCatalog.enemy(&"tank")
	var subtracted := _armored(bolt.damage, tank.armor)
	var map := _lane([&"bolt"])
	_add_wave(map, [[&"tank", 1, 0, 0]])
	var sim := GridwardSim.new(map, GridwardCatalog.new(), 1)
	assert_gte(sim.place_tower(Vector2i(0, 1), &"bolt"), 0)
	assert_true(sim.start_wave())
	sim.step()
	assert_eq(_hp(sim, 0), tank_hp - subtracted)
	assert_gt(subtracted, 1)

	var frost := GridwardCatalog.tower(&"frost")
	var floored := _armored(frost.damage, tank.armor)
	assert_eq(floored, 1)
	var map_frost := _lane([&"frost"])
	_add_wave(map_frost, [[&"tank", 1, 0, 0]])
	var frost_sim := GridwardSim.new(map_frost, GridwardCatalog.new(), 2)
	assert_gte(frost_sim.place_tower(Vector2i(0, 1), &"frost"), 0)
	assert_true(frost_sim.start_wave())
	frost_sim.step()
	assert_eq(_hp(frost_sim, 0), tank_hp - 1)


func test_bolt_should_ignore_flyers() -> void:
	var flyer_hp := GridwardCatalog.enemy(&"flyer").hp
	var map := _lane([&"bolt"])
	_add_wave(map, [[&"flyer", 1, 0, 0]])
	var sim := GridwardSim.new(map, GridwardCatalog.new(), 3)
	assert_gte(sim.place_tower(Vector2i(0, 1), &"bolt"), 0)
	assert_true(sim.start_wave())
	for _i in 40:
		sim.step()
	assert_eq(_hp(sim, 0), flyer_hp)
	assert_false(_has_hit(sim))


func test_flak_should_hit_flyers() -> void:
	var flyer_hp := GridwardCatalog.enemy(&"flyer").hp
	var flak := GridwardCatalog.tower(&"flak")
	var map := _lane([&"flak"])
	_add_wave(map, [[&"flyer", 1, 0, 0]])
	var sim := GridwardSim.new(map, GridwardCatalog.new(), 4)
	assert_gte(sim.place_tower(Vector2i(0, 1), &"flak"), 0)
	assert_true(sim.start_wave())
	sim.step()
	assert_eq(_hp(sim, 0), flyer_hp - flak.damage)
	assert_true(_has_hit(sim))


func test_mortar_should_ignore_flyers() -> void:
	var flyer_hp := GridwardCatalog.enemy(&"flyer").hp
	var map := _lane([&"mortar"])
	_add_wave(map, [[&"flyer", 1, 0, 0]])
	var sim := GridwardSim.new(map, GridwardCatalog.new(), 5)
	assert_gte(sim.place_tower(Vector2i(0, 1), &"mortar"), 0)
	assert_true(sim.start_wave())
	sim.step()
	assert_eq(sim.get_projectiles().size(), 0)
	assert_eq(_hp(sim, 0), flyer_hp)
	assert_false(_has_hit(sim))


func test_frost_should_apply_slow_capped() -> void:
	var grunt := GridwardCatalog.enemy(&"grunt")
	var frost := GridwardCatalog.tower(&"frost")
	var cap := GridwardConfig.new().slow_cap
	var applied := minf(frost.slow_factor, cap)
	assert_lt(applied, cap)

	var map := _lane([&"frost"])
	_add_wave(map, [[&"grunt", 1, 0, 0]])
	var sim := GridwardSim.new(map, GridwardCatalog.new(), 6)
	assert_gte(sim.place_tower(Vector2i(0, 1), &"frost"), 0)
	assert_true(sim.start_wave())
	sim.step()
	var enemy: EnemyState = sim.get_enemies()[0]
	var slow := _status(enemy, StatusEffect.SLOW)
	assert_not_null(slow)
	assert_almost_eq(slow.magnitude, applied, 0.0001)
	assert_eq(slow.remaining_ticks, frost.slow_ticks)
	var before := enemy.position
	sim.step()
	assert_almost_eq(enemy.position.x - before.x, _step_distance(grunt.speed, applied), 0.00001)

	var capped_map := _lane([&"frost"])
	_add_wave(capped_map, [[&"grunt", 1, 0, 0]])
	var capped := GridwardSim.new(capped_map, GridwardCatalog.new(), 7)
	assert_gte(capped.place_tower(Vector2i(0, 1), &"frost"), 0)
	var tower: TowerState = capped.get_towers()[0]
	tower.slow_factor = 0.95
	assert_true(capped.start_wave())
	capped.step()
	var slowed: EnemyState = capped.get_enemies()[0]
	var capped_slow := _status(slowed, StatusEffect.SLOW)
	assert_almost_eq(capped_slow.magnitude, cap, 0.0001)
	var origin := slowed.position
	capped.step()
	assert_almost_eq(slowed.position.x - origin.x, _step_distance(grunt.speed, cap), 0.00001)
	var before_refresh := capped_slow.remaining_ticks
	tower.cooldown = 0
	capped.step()
	assert_eq(capped_slow.remaining_ticks, frost.slow_ticks)
	assert_lt(before_refresh, frost.slow_ticks)
	tower.slow_factor = 0.10
	tower.cooldown = 0
	capped.step()
	assert_almost_eq(capped_slow.magnitude, cap, 0.0001)
	assert_eq(capped_slow.remaining_ticks, frost.slow_ticks - 1)


func test_beam_ramp_should_reset_on_retarget() -> void:
	var map := _lane([&"beam"])
	_add_wave(map, [[&"swarm", 2, 0, 0]])
	var sim := GridwardSim.new(map, GridwardCatalog.new(), 8)
	assert_gte(sim.place_tower(Vector2i(0, 1), &"beam"), 0)
	assert_true(sim.start_wave())
	var damages: Array[int] = []
	var targets: Array[int] = []
	var guard := 0
	while damages.size() < 4 and guard < 80:
		sim.step()
		guard += 1
		for event in sim.drain_events():
			var row: Dictionary = event
			if row["type"] != GridwardEvents.ENEMY_HIT:
				continue
			damages.append(int(row["damage"]))
			targets.append(int(row["id"]))
	assert_eq(damages.size(), 4)
	assert_eq(damages[0], 3)
	assert_eq(damages[1], 4)
	assert_eq(damages[2], 5)
	assert_eq(targets[0], 0)
	assert_eq(targets[1], 0)
	assert_eq(targets[2], 0)
	assert_eq(damages[3], 3)
	assert_eq(targets[3], 1)


func test_swarm_wave_entry_should_spawn_count() -> void:
	var map := _lane([&"bolt"])
	_add_wave(map, [[&"swarm", 5, 0, 0], [&"grunt", 2, 0, 1]])
	var sim := GridwardSim.new(map, GridwardCatalog.new(), 9)
	assert_true(sim.start_wave())
	sim.step()
	assert_eq(_count(sim, &"swarm"), 5)
	assert_eq(_count(sim, &"grunt"), 0)
	sim.step()
	assert_eq(_count(sim, &"swarm"), 5)
	assert_eq(_count(sim, &"grunt"), 2)


func test_burn_should_tick_damage_per_stack() -> void:
	var grunt_hp := GridwardCatalog.enemy(&"grunt").hp
	var bolt := GridwardCatalog.tower(&"bolt")
	var map := _lane([&"bolt"])
	_add_wave(map, [[&"grunt", 1, 0, 0]])
	var sim := GridwardSim.new(map, GridwardCatalog.new(), 10)
	assert_gte(sim.place_tower(Vector2i(0, 1), &"bolt"), 0)
	var tower: TowerState = sim.get_towers()[0]
	tower.burn_stacks = 3
	tower.burn_ticks = 4
	tower.cooldown_ticks = 100
	assert_true(sim.start_wave())
	sim.step()
	assert_eq(_hp(sim, 0), grunt_hp - bolt.damage)
	sim.step()
	assert_eq(_hp(sim, 0), grunt_hp - bolt.damage - 3)
	tower.cooldown = 0
	sim.step()
	var enemy: EnemyState = sim.get_enemies()[0]
	assert_eq(int(_status(enemy, StatusEffect.BURN).magnitude), 5)
	assert_eq(_hp(sim, 0), grunt_hp - bolt.damage - 3 - 3 - bolt.damage)
	var capped_hp := _hp(sim, 0)
	sim.step()
	assert_eq(_hp(sim, 0), capped_hp - 5)


func _armored(raw: int, armor: int) -> int:
	var dealt := raw - armor
	if dealt < 1:
		return 1
	return dealt


func _step_distance(speed: float, slow: float) -> float:
	return speed * (1.0 - slow) * FixedTick.SEC


func _lane(unlocked: Array[StringName]) -> MapDef:
	var map := MapDef.new()
	map.id = &"lane"
	map.width = 12
	map.height = 4
	map.starting_gold = 400
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


func _count(sim: GridwardSim, enemy_id: StringName) -> int:
	var total := 0
	for enemy in sim.get_enemies():
		var body: EnemyState = enemy
		if body.enemy_id == enemy_id:
			total += 1
	return total


func _status(enemy: EnemyState, kind: StringName) -> StatusEffect:
	for effect in enemy.statuses:
		if effect.kind == kind:
			return effect
	return null


func _has_hit(sim: GridwardSim) -> bool:
	for event in sim.drain_events():
		var row: Dictionary = event
		if row["type"] == GridwardEvents.ENEMY_HIT:
			return true
	return false
