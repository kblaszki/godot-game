extends GutTest


func test_cell_to_world_should_center_on_cell() -> void:
	var world := GridwardBoard3D.cell_to_world(Vector2i(2, 3))
	assert_almost_eq(world.x, 2.5, 0.0001)
	assert_almost_eq(world.y, 0.0, 0.0001)
	assert_almost_eq(world.z, 3.5, 0.0001)


func test_world_to_cell_roundtrip() -> void:
	var cell := Vector2i(4, 1)
	var center := GridwardBoard3D.cell_to_world(cell)
	assert_eq(GridwardBoard3D.world_to_cell(center), cell)
	assert_eq(GridwardBoard3D.world_to_cell(center + Vector3(0.49, 3.0, 0.49)), cell)
	assert_eq(GridwardBoard3D.world_to_cell(center + Vector3(0.51, 0.0, 0.0)), cell + Vector2i(1, 0))
	assert_eq(GridwardBoard3D.world_to_cell(GridwardBoard3D.point_to_world(Vector2(0, 1))), Vector2i(0, 1))


func test_yaw_for_xz_delta_should_align_segment() -> void:
	assert_almost_eq(GridwardBoard3D.yaw_for_xz_delta(Vector2(2, 0)), 0.0, 0.001)
	assert_almost_eq(GridwardBoard3D.yaw_for_xz_delta(Vector2(0, 2)), -PI * 0.5, 0.001)
	assert_almost_eq(GridwardBoard3D.yaw_for_xz_delta(Vector2(0, -2)), PI * 0.5, 0.001)


func test_cell_at_screen_should_miss_without_camera() -> void:
	var board := GridwardBoard3D.new()
	assert_true(GridwardBoard3D.is_miss(board.cell_at_screen(Vector2(20, 20))))
	board.free()


func test_headless_sync_should_skip_meshes() -> void:
	var board: GridwardBoard3D = load("res://games/gridward/app/board_3d.tscn").instantiate()
	add_child_autofree(board)
	await wait_frames(1)
	var sim := GridwardSim.new(GridwardCatalog.build_meadow(), GridwardCatalog.new(), 3)
	assert_ne(sim.place_tower(Vector2i(1, 3), &"bolt"), -1)
	assert_true(sim.start_wave())
	sim.step()
	assert_true(sim.get_enemies().size() > 0)
	board.sync_from_sim(sim)
	board.sync_from_sim(sim)
	board.set_ghost(Vector2i(1, 2), true)
	board.set_ghost(GridwardBoard3D.MISS_CELL, false)
	board.fit(Vector2(1280, 720))
	assert_not_null(board.get_camera())
	if OS.has_feature("headless") or DisplayServer.get_name() == "headless":
		assert_eq(_mesh_count(board), 0)


func test_camera_hooks_should_orbit_pan_and_fit() -> void:
	var board: GridwardBoard3D = load("res://games/gridward/app/board_3d.tscn").instantiate()
	add_child_autofree(board)
	await wait_frames(1)
	var sim := GridwardSim.new(GridwardCatalog.build_meadow(), GridwardCatalog.new(), 1)
	board.sync_from_sim(sim)
	board.fit(Vector2(1280, 720))
	var fitted := board.get_camera().global_position
	board.begin_orbit()
	assert_true(board.is_orbiting())
	board.orbit(320.0)
	board.end_orbit()
	assert_false(board.is_orbiting())
	assert_true(fitted.distance_to(board.get_camera().global_position) > 0.2)
	board.fit(Vector2(1280, 720))
	var restored := board.get_camera().global_position
	assert_almost_eq(restored.x, fitted.x, 0.001)
	assert_almost_eq(restored.y, fitted.y, 0.001)
	assert_almost_eq(restored.z, fitted.z, 0.001)
	board.begin_pan()
	assert_true(board.is_panning())
	var before_pan := board.get_camera().global_position
	board.pan(Vector2(48, -12))
	board.end_pan()
	assert_false(board.is_panning())
	assert_true(before_pan.distance_to(board.get_camera().global_position) > 0.05)
	var before_dolly := board.get_camera().global_position.y
	board.dolly(1.4)
	assert_true(board.get_camera().global_position.y < before_dolly - 0.05)
	board.fit(Vector2(1280, 720))
	var framed := board.get_camera().global_position
	assert_almost_eq(framed.x, fitted.x, 0.001)
	assert_almost_eq(framed.y, fitted.y, 0.001)
	assert_almost_eq(framed.z, fitted.z, 0.001)


func test_trauma_should_offset_only_the_camera() -> void:
	var board: GridwardBoard3D = load("res://games/gridward/app/board_3d.tscn").instantiate()
	add_child_autofree(board)
	await wait_frames(1)
	board.fit(Vector2(1280, 720))
	var fitted := board.get_camera().global_position
	var pivot := board.get_node("BoardPivot3D") as Node3D
	var pivot_at := pivot.position
	board.add_trauma(1.0)
	board._process(0.05)
	assert_gt(fitted.distance_to(board.get_camera().global_position), 0.02)
	assert_eq(pivot.position, pivot_at)
	assert_gt(board.get_trauma(), 0.8)


func test_enemy_pool_capacity_should_grow_then_hold() -> void:
	assert_eq(GridwardBoard3D.pooled_capacity(0, 0), 0)
	assert_eq(GridwardBoard3D.pooled_capacity(0, 3), 8)
	assert_eq(GridwardBoard3D.pooled_capacity(8, 9), 16)
	assert_eq(GridwardBoard3D.pooled_capacity(16, 4), 16)


func test_enemy_origin_should_lift_flyers() -> void:
	var flyer := EnemyState.new()
	flyer.enemy_id = &"flyer"
	flyer.is_air = true
	flyer.position = Vector2(2, 3)
	var origin := GridwardBoard3D.enemy_origin(flyer)
	var ground := GridwardBoard3D.point_to_world(flyer.position)
	assert_almost_eq(origin.x, ground.x, 0.0001)
	assert_gt(origin.y, ground.y + 0.8)
	assert_almost_eq(origin.z, ground.z, 0.0001)
	var grunt := EnemyState.new()
	grunt.enemy_id = &"grunt"
	grunt.position = flyer.position
	assert_lt(GridwardBoard3D.enemy_origin(grunt).y, origin.y)


func test_headless_sync_should_anchor_enemies_without_batches() -> void:
	var board: GridwardBoard3D = load("res://games/gridward/app/board_3d.tscn").instantiate()
	add_child_autofree(board)
	await wait_frames(1)
	var sim := GridwardSim.new(GridwardCatalog.build_meadow(), GridwardCatalog.new(), 3)
	assert_true(sim.start_wave())
	sim.step()
	var enemy := sim.get_enemies()[0] as EnemyState
	board.sync_from_sim(sim)
	var origin := GridwardBoard3D.enemy_origin(enemy)
	var anchor := board.enemy_anchor(enemy.id)
	assert_almost_eq(anchor.x, origin.x, 0.0001)
	assert_almost_eq(anchor.y, origin.y, 0.0001)
	assert_almost_eq(anchor.z, origin.z, 0.0001)
	var enemies := board.get_node("BoardPivot3D/Enemies") as Node3D
	assert_eq(enemies.get_child_count(), 0)
	assert_eq(board.enemy_pool_capacity(enemy.enemy_id), 0)
	var idle := GridwardSim.new(GridwardCatalog.build_meadow(), GridwardCatalog.new(), 3)
	board.sync_from_sim(idle)
	assert_true(is_inf(board.enemy_anchor(enemy.id).x))


func test_shake_toggle_should_ignore_trauma() -> void:
	var board := GridwardBoard3D.new()
	board.add_trauma(1.0)
	assert_gt(board.get_trauma(), 0.9)
	board.set_shake_enabled(false)
	assert_false(board.is_shake_enabled())
	assert_eq(board.get_trauma(), 0.0)
	board.add_trauma(1.0)
	assert_eq(board.get_trauma(), 0.0)
	board.set_shake_enabled(true)
	board.add_trauma(0.4)
	assert_gt(board.get_trauma(), 0.3)
	board.free()


func _mesh_count(node: Node) -> int:
	var count := 0
	if node is MeshInstance3D:
		count += 1
	for child in node.get_children():
		count += _mesh_count(child)
	return count
