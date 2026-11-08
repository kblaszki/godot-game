extends GutTest

const _STEP_LIMIT := 800


func test_start_wave_should_enter_wave_phase() -> void:
	var sim := _meadow(3)
	assert_eq(sim.get_phase(), GridwardSim.Phase.BUILD)
	assert_eq(sim.get_gold(), 120)
	assert_eq(sim.get_lives(), 20)
	assert_eq(sim.get_wave_index(), 0)
	assert_eq(sim.get_enemies().size(), 0)
	assert_true(sim.start_wave())
	assert_eq(sim.get_phase(), GridwardSim.Phase.WAVE)
	assert_false(sim.start_wave())
	sim.step()
	var enemies := sim.get_enemies()
	assert_eq(enemies.size(), 1)
	var enemy: EnemyState = enemies[0]
	assert_eq(enemy.id, 0)
	assert_eq(enemy.enemy_id, &"grunt")
	assert_eq(enemy.hp, GridwardCatalog.enemy(&"grunt").hp)
	assert_gt(enemy.position.x, 0.0)
	assert_almost_eq(enemy.position.y, 1.0, 0.0001)
	var events := sim.drain_events()
	assert_eq(events.size(), 2)
	assert_eq(events[0]["type"], GridwardEvents.WAVE_STARTED)
	assert_eq(int(events[0]["wave_index"]), 0)
	assert_eq(events[1]["type"], GridwardEvents.ENEMY_SPAWNED)
	assert_eq(sim.drain_events().size(), 0)
	for _i in 70:
		sim.step()
	var spawned := sim.get_enemies()
	assert_eq(spawned.size(), 2)
	var first: EnemyState = spawned[0]
	var second: EnemyState = spawned[1]
	assert_eq(first.id, 0)
	assert_eq(second.id, 1)
	assert_eq(second.enemy_id, &"grunt")
	assert_gt(first.position.x, second.position.x)


func test_enemy_should_follow_waypoints_without_stalling() -> void:
	var waypoints := _zigzag(40, 0.005)
	var map := _lane(9, 1, 1, 30, waypoints)
	var sim := GridwardSim.new(map, GridwardCatalog.new(), 5)
	var speed := GridwardCatalog.enemy(&"grunt").speed
	assert_true(sim.start_wave())
	for n in 8:
		sim.step()
		assert_eq(sim.get_phase(), GridwardSim.Phase.WAVE)
		var enemy: EnemyState = sim.get_enemies()[0]
		var expected := _point_at(waypoints, float(n + 1) * speed * FixedTick.SEC)
		assert_almost_eq(enemy.position.x, expected.x, 0.000001)
		assert_almost_eq(enemy.position.y, expected.y, 0.000001)
		assert_gt(enemy.segment, 1)
	var after_one := _point_at(waypoints, speed * FixedTick.SEC)
	assert_gt(after_one.distance_to(waypoints[1]), 0.001)


func test_leak_should_decrement_lives_and_remove_enemy() -> void:
	var waypoints := PackedVector2Array([Vector2(0, 1), Vector2(2, 1)])
	var sim := GridwardSim.new(_lane(5, 2, 1, 10, waypoints), GridwardCatalog.new(), 2)
	assert_true(sim.start_wave())
	var guard := 0
	while sim.get_phase() == GridwardSim.Phase.WAVE and guard < _STEP_LIMIT:
		sim.step()
		guard += 1
	assert_eq(sim.get_enemies().size(), 0)
	assert_eq(sim.get_lives(), 4)
	assert_eq(sim.get_gold(), 40)
	assert_eq(sim.get_phase(), GridwardSim.Phase.WAVE_CLEAR)
	assert_eq(sim.get_wave_index(), 0)
	assert_false(sim.start_wave())
	var leaked := sim.drain_events()
	assert_true(_has_type(leaked, GridwardEvents.ENEMY_LEAKED))
	assert_true(_has_type(leaked, GridwardEvents.WAVE_CLEARED))
	sim.step()
	assert_eq(sim.get_phase(), GridwardSim.Phase.BUILD)
	assert_eq(sim.get_wave_index(), 1)
	assert_true(sim.start_wave())
	sim.step()
	var next: EnemyState = sim.get_enemies()[0]
	var scaled := roundi(float(GridwardCatalog.enemy(&"grunt").hp) * pow(1.12, 1.0))
	assert_eq(next.hp, scaled)


func test_clearing_last_wave_should_victory() -> void:
	var waypoints := PackedVector2Array([Vector2(0, 0), Vector2(1, 0)])
	var sim := GridwardSim.new(_lane(8, 1, 2, 20, waypoints), GridwardCatalog.new(), 4)
	assert_true(sim.start_wave())
	var saw_clear := false
	var guard := 0
	while sim.get_phase() != GridwardSim.Phase.VICTORY and guard < _STEP_LIMIT:
		if sim.get_phase() == GridwardSim.Phase.WAVE_CLEAR:
			saw_clear = true
		sim.step()
		guard += 1
	assert_true(saw_clear)
	assert_eq(sim.get_phase(), GridwardSim.Phase.VICTORY)
	assert_eq(sim.get_lives(), 6)
	assert_eq(sim.get_enemies().size(), 0)
	assert_eq(sim.get_wave_index(), 0)
	assert_false(sim.start_wave())
	sim.step()
	assert_eq(sim.get_phase(), GridwardSim.Phase.VICTORY)
	assert_true(_has_type(sim.drain_events(), GridwardEvents.VICTORY))


func test_lives_zero_should_defeat() -> void:
	var waypoints := PackedVector2Array([Vector2(0, 0), Vector2(2, 0)])
	var sim := GridwardSim.new(_lane(1, 1, 2, 30, waypoints), GridwardCatalog.new(), 8)
	assert_true(sim.start_wave())
	var guard := 0
	while sim.get_phase() == GridwardSim.Phase.WAVE and guard < _STEP_LIMIT:
		sim.step()
		guard += 1
	assert_eq(sim.get_phase(), GridwardSim.Phase.DEFEAT)
	assert_eq(sim.get_lives(), 0)
	assert_eq(sim.get_enemies().size(), 1)
	var held: EnemyState = sim.get_enemies()[0]
	var held_position := held.position
	sim.step()
	assert_eq(sim.get_phase(), GridwardSim.Phase.DEFEAT)
	assert_eq(sim.get_lives(), 0)
	assert_almost_eq(held.position.x, held_position.x, 0.000001)
	assert_almost_eq(held.position.y, held_position.y, 0.000001)
	assert_false(sim.start_wave())
	var events := sim.drain_events()
	assert_true(_has_type(events, GridwardEvents.DEFEAT))
	assert_false(_has_type(events, GridwardEvents.VICTORY))
	assert_false(_has_type(events, GridwardEvents.WAVE_CLEARED))


func test_same_seed_should_match_enemy_positions_after_n_steps() -> void:
	var steps := 180
	var left := _run_meadow(11, steps)
	var right := _run_meadow(11, steps)
	assert_eq(left["phase"], right["phase"])
	assert_eq(left["gold"], right["gold"])
	assert_eq(left["lives"], right["lives"])
	assert_eq(left["wave"], right["wave"])
	var left_enemies: Array = left["enemies"]
	var right_enemies: Array = right["enemies"]
	assert_eq(left_enemies.size(), right_enemies.size())
	assert_gt(left_enemies.size(), 1)
	for i in left_enemies.size():
		var a: Dictionary = left_enemies[i]
		var b: Dictionary = right_enemies[i]
		assert_eq(a["id"], b["id"])
		assert_eq(a["enemy_id"], b["enemy_id"])
		assert_eq(a["hp"], b["hp"])
		assert_eq(a["segment"], b["segment"])
		assert_almost_eq(float(a["x"]), float(b["x"]), 0.000001)
		assert_almost_eq(float(a["y"]), float(b["y"]), 0.000001)
		assert_almost_eq(float(a["segment_distance"]), float(b["segment_distance"]), 0.000001)
	assert_gt(float(left_enemies[0]["x"]), float(left_enemies[1]["x"]))
	var left_events: Array = left["events"]
	var right_events: Array = right["events"]
	assert_eq(left_events.size(), right_events.size())
	assert_gt(left_events.size(), 0)
	for i in left_events.size():
		assert_eq(left_events[i], right_events[i])


func _meadow(seed: int) -> GridwardSim:
	return GridwardSim.new(GridwardCatalog.build_meadow(), GridwardCatalog.new(), seed)


func _run_meadow(seed: int, steps: int) -> Dictionary:
	var sim := _meadow(seed)
	assert_true(sim.start_wave())
	for _i in steps:
		sim.step()
	var enemies: Array = []
	for enemy in sim.get_enemies():
		var body: EnemyState = enemy
		enemies.append({
			"id": body.id,
			"enemy_id": body.enemy_id,
			"hp": body.hp,
			"segment": body.segment,
			"segment_distance": body.segment_distance,
			"x": body.position.x,
			"y": body.position.y,
		})
	return {
		"phase": sim.get_phase(),
		"gold": sim.get_gold(),
		"lives": sim.get_lives(),
		"wave": sim.get_wave_index(),
		"enemies": enemies,
		"events": sim.drain_events(),
	}


func _lane(lives: int, waves: int, count: int, spacing: int, waypoints: PackedVector2Array) -> MapDef:
	var map := MapDef.new()
	map.id = &"lane"
	map.width = 8
	map.height = 4
	map.starting_gold = 40
	map.starting_lives = lives
	map.waypoints = waypoints
	for _i in waves:
		var wave := WaveDef.new()
		wave.entries.append({
			"enemy_id": &"grunt",
			"count": count,
			"spacing_ticks": spacing,
			"delay_ticks": 0,
		})
		map.waves.append(wave)
	return map


func _zigzag(segments: int, length: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var cursor := Vector2.ZERO
	points.append(cursor)
	for i in segments:
		if i % 2 == 0:
			cursor.x += length
		else:
			cursor.y += length
		points.append(cursor)
	return points


func _point_at(waypoints: PackedVector2Array, distance: float) -> Vector2:
	var remaining := distance
	var segment := 0
	while remaining > 0.0 and segment < waypoints.size() - 1:
		var start: Vector2 = waypoints[segment]
		var finish: Vector2 = waypoints[segment + 1]
		var delta := finish - start
		var length := delta.length()
		if length <= 0.0000001:
			segment += 1
			continue
		if remaining < length:
			return start + delta * (remaining / length)
		remaining -= length
		segment += 1
	return waypoints[waypoints.size() - 1]


func _has_type(events: Array, event_type: StringName) -> bool:
	for event in events:
		var row: Dictionary = event
		if row["type"] == event_type:
			return true
	return false
