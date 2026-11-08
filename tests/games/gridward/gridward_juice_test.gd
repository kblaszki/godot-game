extends GutTest

const PLAY_PATH := "res://games/gridward/app/play.tscn"
const ICON_JSON := "res://games/gridward/assets/pxl/icons.json"


class StepStub:
	extends GridwardSim

	var step_count: int = 0

	func step() -> void:
		step_count += 1


func test_reaction_should_stop_on_big_kills_and_shake_on_leak() -> void:
	var big := GridwardAudio.reaction(GridwardEvents.enemy_killed(3, &"boss", 100, 200))
	assert_eq(big["cue"], GridwardAudio.CUE_KILL_BIG)
	assert_eq(int(big["hit_stop"]), GridwardAudio.HIT_STOP_STEPS)
	assert_gt(float(big["trauma"]), 0.0)
	var rich := GridwardAudio.reaction(GridwardEvents.enemy_killed(6, &"tank", 50, 50))
	assert_eq(int(rich["hit_stop"]), GridwardAudio.HIT_STOP_STEPS)
	var small := GridwardAudio.reaction(GridwardEvents.enemy_killed(4, &"grunt", 8, 8))
	assert_eq(small["cue"], GridwardAudio.CUE_KILL)
	assert_eq(int(small["hit_stop"]), 0)
	assert_eq(float(small["trauma"]), 0.0)
	var leak := GridwardAudio.reaction(GridwardEvents.enemy_leaked(5, &"grunt", 19))
	assert_eq(leak["cue"], GridwardAudio.CUE_LEAK)
	assert_gt(float(leak["trauma"]), float(big["trauma"]))
	assert_eq(int(leak["hit_stop"]), 0)


func test_big_kill_should_skip_following_sim_steps() -> void:
	var map := GridwardCatalog.build_meadow()
	var stub := StepStub.new(map, GridwardCatalog.new(), 1)
	var play = load(PLAY_PATH).instantiate()
	play.bind_sim(stub, map)
	play.process_mode = Node.PROCESS_MODE_DISABLED
	add_child_autofree(play)
	await wait_frames(1)
	var spy := AudioSpy.new()
	(play.get_node("GridwardAudio") as GridwardAudio).set_port(spy)
	play._dispatch_events([GridwardEvents.enemy_killed(1, &"boss", 100, 100)])
	assert_eq(play._skip_sim_steps, GridwardAudio.HIT_STOP_STEPS)
	assert_eq(spy.calls.size(), 1)
	assert_eq(spy.calls[0]["id"], GridwardAudio.CUE_KILL_BIG)
	stub.step_count = 0
	play._process(0.0)
	assert_eq(stub.step_count, 0)
	assert_eq(play._skip_sim_steps, GridwardAudio.HIT_STOP_STEPS - 1)
	play._process(0.0)
	play._process(0.0)
	play._process(0.0)
	assert_eq(stub.step_count, 0)
	assert_eq(play._skip_sim_steps, 0)
	play._process(0.0)
	assert_eq(stub.step_count, 1)


func test_leak_event_should_add_camera_trauma() -> void:
	var play = await _new_play()
	var board := play.get_node("BoardRoot/SubViewportContainer/SubViewport/Board3D") as GridwardBoard3D
	var spy := AudioSpy.new()
	(play.get_node("GridwardAudio") as GridwardAudio).set_port(spy)
	assert_eq(board.get_trauma(), 0.0)
	play._dispatch_events([GridwardEvents.enemy_leaked(1, &"runner", 19)])
	assert_gt(board.get_trauma(), 0.5)
	assert_eq(spy.calls[0]["id"], GridwardAudio.CUE_LEAK)
	assert_eq(play.get_sim().get_lives(), 20)


func test_play_juice_should_match_headless_sim() -> void:
	var map := GridwardCatalog.build_meadow()
	var played := GridwardSim.new(map, GridwardCatalog.new(), 11)
	var plain := GridwardSim.new(GridwardCatalog.build_meadow(), GridwardCatalog.new(), 11)
	assert_ne(played.place_tower(Vector2i(1, 2), &"bolt"), -1)
	assert_ne(plain.place_tower(Vector2i(1, 2), &"bolt"), -1)
	assert_true(played.start_wave())
	assert_true(plain.start_wave())
	played.drain_events()
	plain.drain_events()
	var play = load(PLAY_PATH).instantiate()
	play.bind_sim(played, map)
	play.process_mode = Node.PROCESS_MODE_DISABLED
	add_child_autofree(play)
	await wait_frames(1)
	var spy := AudioSpy.new()
	(play.get_node("GridwardAudio") as GridwardAudio).set_port(spy)
	for _i in 80:
		play._process(0.016)
		plain.step()
	assert_eq(played.get_gold(), plain.get_gold())
	assert_eq(played.get_lives(), plain.get_lives())
	assert_eq(played.get_phase(), plain.get_phase())
	assert_eq(played.get_wave_index(), plain.get_wave_index())
	assert_eq(played.get_enemies().size(), plain.get_enemies().size())
	assert_eq(played.get_projectiles().size(), plain.get_projectiles().size())
	assert_gt(spy.calls.size(), 0)


func test_icons_sheet_should_parse_with_pxl_sheet() -> void:
	var sheet := PxlSheet.parse(FileAccess.get_file_as_string(ICON_JSON))
	assert_true(sheet.is_valid())
	for tower_id in GridwardCatalog.TOWER_IDS:
		var rect := sheet.frame_rect(tower_id)
		assert_gt(rect.size.x, 0, str(tower_id))
		assert_gt(rect.size.y, 0, str(tower_id))


func test_build_buttons_should_use_nearest_tower_icons() -> void:
	var play = await _new_play()
	var bar := play.get_node("BottomDock/Margin/Column/ActionRow/BuildBar") as HBoxContainer
	assert_eq(bar.get_child_count(), GridwardCatalog.TOWER_IDS.size())
	var index := 0
	for child in bar.get_children():
		var button := child as Button
		var tower_id: StringName = GridwardCatalog.TOWER_IDS[index]
		assert_not_null(button.icon, str(tower_id))
		assert_false(button.expand_icon)
		assert_eq(button.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)
		index += 1


func _new_play():
	var play = load(PLAY_PATH).instantiate()
	play.process_mode = Node.PROCESS_MODE_DISABLED
	add_child_autofree(play)
	await wait_frames(1)
	return play
