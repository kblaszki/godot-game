extends GutTest

const LAB_HOST_PATH := "res://lab/lab_host.tscn"
const LAUNCHER_PATH := "res://lab/launcher.tscn"
const HOST_PATH := "res://games/gridward/app/host.tscn"
const MENU_PATH := "res://games/gridward/app/menu.tscn"
const MAP_SELECT_PATH := "res://games/gridward/app/map_select.tscn"
const PLAY_PATH := "res://games/gridward/app/play.tscn"
const PAUSE_PATH := "res://games/gridward/app/pause_menu.tscn"
const RESULTS_PATH := "res://games/gridward/app/results.tscn"
const PROGRESS_PATH := "user://gridward/host_flow_progress.txt"


func before_each() -> void:
	_wipe_progress()


func after_each() -> void:
	_wipe_progress()


func test_menu_should_open_map_select_and_quit_returns_to_lab() -> void:
	var opened = await _boot()
	var lab: Node = opened[0]
	var host: Node = opened[1]
	var lab_content: Node = lab.get_node("Content")
	var content: Node = host.get_node("Content")
	assert_eq(str(host.get_meta("scene_path")), HOST_PATH)
	var menu: Node = content.get_child(0)
	assert_eq(str(menu.get_meta("scene_path")), MENU_PATH)

	(menu.get_node("Center/Column/Play") as Button).pressed.emit()
	host._flush()
	var select: Node = content.get_child(0)
	assert_eq(str(select.get_meta("scene_path")), MAP_SELECT_PATH)
	var citadel := select.get_node("Center/Column/Maps/Citadel") as Button
	assert_true(citadel.disabled)
	assert_true(str(citadel.text).contains("locked"))
	var meadow := select.get_node("Center/Column/Maps/Meadow") as Button
	assert_false(meadow.disabled)
	await wait_frames(1)
	assert_true(meadow.has_focus())

	(select.get_node("Center/Column/Back") as Button).pressed.emit()
	host._flush()
	assert_eq(str(content.get_child(0).get_meta("scene_path")), MENU_PATH)

	host.submit(SceneRequest.quit())
	host._flush()
	await wait_frames(1)
	assert_eq(lab_content.get_child_count(), 1)
	assert_eq(str(lab_content.get_child(0).get_meta("scene_path")), LAUNCHER_PATH)


func test_pause_should_push_and_resume_pop() -> void:
	var opened = await _boot()
	var host: Node = opened[1]
	var content: Node = host.get_node("Content")
	var play := _start_meadow(host)
	assert_eq(str(play.get_meta("scene_path")), PLAY_PATH)

	var menu_button := play.get_node("BottomDock/Margin/Column/ActionRow/Menu") as Button
	menu_button.pressed.emit()
	host._flush()
	assert_eq(content.get_child_count(), 2)
	var pause: Node = content.get_child(1)
	assert_eq(str(pause.get_meta("scene_path")), PAUSE_PATH)
	assert_eq(play.process_mode, Node.PROCESS_MODE_DISABLED)
	var resume := pause.get_node("Center/Panel/Margin/Column/Resume") as Button
	await wait_frames(1)
	assert_true(resume.has_focus())

	resume.pressed.emit()
	host._flush()
	assert_eq(content.get_child_count(), 1)
	assert_true(is_instance_valid(play))
	assert_eq(str(play.get_meta("scene_path")), PLAY_PATH)
	assert_eq(play.process_mode, Node.PROCESS_MODE_INHERIT)


func test_play_defeat_should_open_results_then_map_select() -> void:
	var opened = await _boot()
	var host: Node = opened[1]
	var content: Node = host.get_node("Content")
	var play := _start_meadow(host)
	var menu_button := play.get_node("BottomDock/Margin/Column/ActionRow/Menu") as Button
	menu_button.pressed.emit()
	host._flush()
	var pause: Node = content.get_child(1)
	(pause.get_node("Center/Panel/Margin/Column/Resume") as Button).pressed.emit()
	host._flush()
	assert_eq(play.process_mode, Node.PROCESS_MODE_INHERIT)

	var leak := _leak_map()
	var sim := GridwardSim.new(leak, GridwardCatalog.new(), 1)
	assert_true(sim.start_wave())
	play.bind_sim(sim, leak)

	var results: Node = null
	for _i in 90:
		await wait_frames(1)
		if content.get_child_count() == 1:
			var top: Node = content.get_child(0)
			if str(top.get_meta("scene_path", "")) == RESULTS_PATH:
				results = top
				break
	assert_not_null(results)
	assert_eq((results.get_node("Center/Column/Title") as Label).text, "Defeat")
	assert_eq((results.get_node("Center/Column/Stars") as Label).text, "No stars")
	var again := results.get_node("Center/Column/MapSelect") as Button
	await wait_frames(1)
	assert_true(again.has_focus())
	again.pressed.emit()
	host._flush()
	var select: Node = content.get_child(0)
	assert_eq(str(select.get_meta("scene_path")), MAP_SELECT_PATH)
	assert_true((select.get_node("Center/Column/Maps/Citadel") as Button).disabled)


func _start_meadow(host: Node) -> Node:
	var content: Node = host.get_node("Content")
	var menu: Node = content.get_child(0)
	(menu.get_node("Center/Column/Play") as Button).pressed.emit()
	host._flush()
	var select: Node = content.get_child(0)
	assert_eq(str(select.get_meta("scene_path")), MAP_SELECT_PATH)
	(select.get_node("Center/Column/Start") as Button).pressed.emit()
	host._flush()
	return content.get_child(0)


func _boot():
	var lab: Node = load(LAB_HOST_PATH).instantiate()
	lab.set_meta("gridward_progress_path", PROGRESS_PATH)
	add_child_autofree(lab)
	await wait_frames(1)
	lab.submit(SceneRequest.replace(HOST_PATH))
	lab._flush()
	await wait_frames(1)
	var host: Node = lab.get_node("Content").get_child(0)
	return [lab, host]


func _leak_map() -> MapDef:
	var map := MapDef.new()
	map.id = &"meadow"
	map.width = 4
	map.height = 1
	map.starting_gold = 0
	map.starting_lives = 1
	map.waypoints = PackedVector2Array([Vector2(0, 0), Vector2(1, 0)])
	map.unlocked_towers = [&"bolt"]
	var wave := WaveDef.new()
	wave.entries.append({
		"enemy_id": &"runner",
		"count": 1,
		"spacing_ticks": 10,
		"delay_ticks": 0,
	})
	map.waves.append(wave)
	map.apply_buildable_off_path()
	return map


func _wipe_progress() -> void:
	for item in [PROGRESS_PATH, PROGRESS_PATH + ".tmp"]:
		if FileAccess.file_exists(item):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(item))
