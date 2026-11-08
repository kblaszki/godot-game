extends GutTest

const LAB_HOST_PATH := "res://lab/lab_host.tscn"
const LAUNCHER_PATH := "res://lab/launcher.tscn"
const HOST_PATH := "res://games/gridward/app/host.tscn"
const MENU_PATH := "res://games/gridward/app/menu.tscn"
const PLAY_PATH := "res://games/gridward/app/play.tscn"


func test_menu_should_replace_into_play_and_quit_returns_to_lab() -> void:
	var lab: Node = load(LAB_HOST_PATH).instantiate()
	add_child_autofree(lab)
	await wait_frames(1)
	var lab_content: Node = lab.get_node("Content")

	lab.submit(SceneRequest.replace(HOST_PATH))
	lab._flush()
	await wait_frames(1)

	var host: Node = lab_content.get_child(0)
	assert_eq(str(host.get_meta("scene_path")), HOST_PATH)
	var content: Node = host.get_node("Content")
	assert_eq(content.get_child_count(), 1)
	var menu: Node = content.get_child(0)
	assert_eq(str(menu.get_meta("scene_path")), MENU_PATH)

	var play_button := menu.get_node("Center/Column/Play") as Button
	play_button.pressed.emit()
	host._flush()
	assert_eq(content.get_child_count(), 1)
	assert_eq(str(content.get_child(0).get_meta("scene_path")), PLAY_PATH)

	host.submit(SceneRequest.quit())
	host._flush()
	await wait_frames(1)
	assert_eq(lab_content.get_child_count(), 1)
	assert_eq(str(lab_content.get_child(0).get_meta("scene_path")), LAUNCHER_PATH)
