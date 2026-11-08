extends GutTest

const PLAY_PATH := "res://games/gridward/app/play.tscn"


class StepStub:
	extends GridwardSim

	var step_count: int = 0

	func step() -> void:
		step_count += 1


func test_play_should_place_tower_via_sim_api() -> void:
	var play = await _new_play()
	play._on_build_pressed(&"bolt")
	assert_eq(play.place_selected_at(Vector2i(0, 1)), -1)
	var id: int = play.place_selected_at(Vector2i(0, 0))
	assert_gt(id, -1)
	var sim: GridwardSim = play.get_sim()
	assert_eq(sim.get_towers().size(), 1)
	var tower := sim.get_towers()[0] as TowerState
	assert_eq(tower.cell, Vector2i(0, 0))
	assert_eq(tower.tower_id, &"bolt")
	assert_eq(sim.get_gold(), 70)
	assert_eq((play.get_node("LivesGold/Margin/Column/Lives") as Label).text, "Lives 20")
	assert_eq((play.get_node("LivesGold/Margin/Column/Gold") as Label).text, "Gold 70")
	assert_eq((play.get_node("WaveCard/Margin/Column/Wave") as Label).text, "Wave 1/10")
	play._on_build_pressed(&"mortar")
	assert_eq(play.place_selected_at(Vector2i(1, 0)), -1)
	assert_eq(sim.get_towers().size(), 1)


func test_tower_panel_should_upgrade_sell_and_retarget() -> void:
	var play = await _new_play()
	play._on_build_pressed(&"bolt")
	assert_gt(play.place_selected_at(Vector2i(0, 0)), -1)
	var panel := play.get_node("TowerPanel") as PanelContainer
	assert_true(panel.visible)
	var upgrade := play.get_node("TowerPanel/Margin/Column/Upgrade") as Button
	upgrade.pressed.emit()
	var tower := play.get_sim().get_towers()[0] as TowerState
	assert_eq(tower.tier, 1)
	var targeting := play.get_node("TowerPanel/Margin/Column/Targeting") as OptionButton
	targeting.item_selected.emit(1)
	assert_eq(tower.targeting, TowerState.TARGET_LAST)
	var sell := play.get_node("TowerPanel/Margin/Column/Sell") as Button
	sell.pressed.emit()
	assert_eq(play.get_sim().get_towers().size(), 0)
	assert_false((play.get_node("TowerPanel") as PanelContainer).visible)


func test_start_wave_button_should_enter_wave_phase() -> void:
	var play = await _new_play()
	var preview := play.get_node("BottomDock/Margin/Column/Preview") as Label
	assert_true(preview.text.contains("4 grunt"))
	var button := play.get_node("BottomDock/Margin/Column/ActionRow/StartWave") as Button
	assert_eq(button.text, "Start Wave")
	assert_false(button.disabled)
	button.pressed.emit()
	assert_eq(play.get_sim().get_phase(), GridwardSim.Phase.WAVE)
	assert_true(button.disabled)


func test_speed_toggle_should_double_steps_per_frame() -> void:
	var map := GridwardCatalog.build_meadow()
	var stub := StepStub.new(map, GridwardCatalog.new(), 1)
	var play = load(PLAY_PATH).instantiate()
	play.bind_sim(stub, map)
	play.process_mode = Node.PROCESS_MODE_DISABLED
	add_child_autofree(play)
	await wait_frames(1)
	var speed := play.get_node("WaveCard/Margin/Column/Speed") as Button
	assert_eq(speed.text, "1x")
	assert_false(play.is_speed_2x())
	stub.step_count = 0
	play._process(0.0)
	assert_eq(stub.step_count, 1)
	play.toggle_speed()
	assert_true(play.is_speed_2x())
	assert_eq(speed.text, "2x")
	stub.step_count = 0
	play._process(0.0)
	assert_eq(stub.step_count, 2)
	play.toggle_speed()
	stub.step_count = 0
	play._process(0.0)
	assert_eq(stub.step_count, 1)


func test_meadow_tutorial_should_teach_then_test() -> void:
	var play = await _new_play()
	assert_true(play.meadow_hint(0, GridwardSim.Phase.BUILD, true).begins_with("Teach:"))
	assert_true(play.meadow_hint(1, GridwardSim.Phase.BUILD, false).begins_with("Test:"))
	assert_true(play.meadow_hint(2, GridwardSim.Phase.BUILD, false).begins_with("Teach:"))
	assert_true(play.meadow_hint(5, GridwardSim.Phase.BUILD, false).begins_with("Test:"))
	assert_eq(play.meadow_hint(0, GridwardSim.Phase.VICTORY, false), "")
	var hint := play.get_node("TutorialHint/Text") as Label
	assert_true(hint.text.begins_with("Teach:"))
	assert_true(hint.text.contains("Bolt"))
	assert_true((play.get_node("TutorialHint") as CanvasItem).visible)
	assert_gt(play.place_selected_at(Vector2i(0, 0)), -1)
	assert_true(hint.text.contains("Start Wave"))
	var start := play.get_node("BottomDock/Margin/Column/ActionRow/StartWave") as Button
	start.pressed.emit()
	assert_true(hint.text.contains("Grunts"))
	var bend := GridwardCatalog.build_bend()
	play.bind_sim(GridwardSim.new(bend, GridwardCatalog.new(), 1), bend)
	assert_eq(play.tutorial_text(), "")
	assert_false((play.get_node("TutorialHint") as CanvasItem).visible)


func test_shake_button_should_block_leak_trauma() -> void:
	var play = await _new_play()
	var board := play.get_node("BoardRoot/SubViewportContainer/SubViewport/Board3D") as GridwardBoard3D
	var button := play.get_node("WaveCard/Margin/Column/Shake") as Button
	assert_eq(button.text, "Shake On")
	assert_true(play.is_screen_shake_enabled())
	assert_true(board.is_shake_enabled())
	button.pressed.emit()
	assert_eq(button.text, "Shake Off")
	assert_false(board.is_shake_enabled())
	play._dispatch_events([GridwardEvents.enemy_leaked(1, &"runner", 19)])
	assert_eq(board.get_trauma(), 0.0)
	button.pressed.emit()
	play._dispatch_events([GridwardEvents.enemy_leaked(2, &"runner", 19)])
	assert_gt(board.get_trauma(), 0.5)


func _new_play():
	var play = load(PLAY_PATH).instantiate()
	play.process_mode = Node.PROCESS_MODE_DISABLED
	add_child_autofree(play)
	await wait_frames(1)
	return play
