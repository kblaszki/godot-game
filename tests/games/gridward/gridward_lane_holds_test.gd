extends GutTest

## Meadow waves after the teach beats and before the late mix.
const _MID_WAVES: Array[int] = [3, 4, 5, 6]
const _SAFETY := 1.15


func test_meadow_mid_waves_should_lane_hold_on_reference_loadout() -> void:
	var straight := PackedVector2Array([Vector2(0, 1), Vector2(12, 1)])
	var chord := GridwardSim.path_coverage_length(straight, Vector2(6, 0), 2.5)
	assert_almost_eq(chord, 2.0 * sqrt(2.5 * 2.5 - 1.0), 0.001)

	var map := GridwardCatalog.build_meadow()
	var config := GridwardConfig.new()
	var bolt := GridwardCatalog.tower(&"bolt")
	var cells: Array[Vector2i] = [Vector2i(4, 0), Vector2i(8, 0)]
	var spent := 0
	for cell in cells:
		assert_true(map.is_buildable(cell), "reference cell %s" % cell)
		spent += bolt.cost
	assert_lte(spent, map.starting_gold)

	var dps := GridwardSim.tower_dps(bolt.damage, bolt.cooldown_ticks)
	assert_almost_eq(dps, 24.0, 0.0001)
	for wave_index in _MID_WAVES:
		var wave: WaveDef = map.waves[wave_index]
		var seen := {}
		for entry in wave.entries:
			var row: Dictionary = entry
			var enemy_id: StringName = row["enemy_id"]
			if seen.has(enemy_id):
				continue
			seen[enemy_id] = true
			var enemy := GridwardCatalog.enemy(enemy_id)
			var hp := GridwardSim.scaled_enemy_hp(enemy.hp, wave_index, config.hp_scale, config.difficulty_hp)
			var damage := 0.0
			for cell in cells:
				var length := GridwardSim.path_coverage_length(map.waypoints, Vector2(cell), bolt.range)
				damage += GridwardSim.estimated_lane_damage(dps, length, enemy.speed)
			assert_gte(
				damage,
				float(hp) * _SAFETY,
				"wave %s %s hp %s" % [wave_index, enemy_id, hp]
			)
