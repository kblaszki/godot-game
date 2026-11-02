extends GutTest

const LAB_HOST_PATH := "res://lab/lab_host.tscn"
const LAUNCHER_PATH := "res://lab/launcher.tscn"
const PONG_HOST_PATH := "res://games/pong/app/host.tscn"


func test_lab_boot_should_show_launcher() -> void:
	var lab: Node = load(LAB_HOST_PATH).instantiate()
	add_child_autofree(lab)
	await wait_frames(1)
	var content: Node = lab.get_node("Content")
	assert_eq(content.get_child_count(), 1)
	assert_eq(str(content.get_child(0).get_meta("scene_path")), LAUNCHER_PATH)


func test_return_to_launcher_should_replace_pong_host() -> void:
	var lab: Node = load(LAB_HOST_PATH).instantiate()
	add_child_autofree(lab)
	await wait_frames(1)
	var content: Node = lab.get_node("Content")

	lab.submit(SceneRequest.replace(PONG_HOST_PATH))
	lab._flush()
	assert_eq(content.get_child_count(), 1)
	assert_eq(str(content.get_child(0).get_meta("scene_path")), PONG_HOST_PATH)

	lab.return_to_launcher()
	assert_eq(content.get_child_count(), 1)
	assert_eq(str(content.get_child(0).get_meta("scene_path")), LAUNCHER_PATH)


func test_pong_quit_should_return_to_launcher_when_nested() -> void:
	var lab: Node = load(LAB_HOST_PATH).instantiate()
	add_child_autofree(lab)
	await wait_frames(1)
	var content: Node = lab.get_node("Content")

	lab.submit(SceneRequest.replace(PONG_HOST_PATH))
	lab._flush()
	await wait_frames(1)
	var pong: Node = content.get_child(0)
	assert_eq(str(pong.get_meta("scene_path")), PONG_HOST_PATH)

	pong.submit(SceneRequest.quit())
	pong._flush()
	await wait_frames(1)
	assert_eq(content.get_child_count(), 1)
	assert_eq(str(content.get_child(0).get_meta("scene_path")), LAUNCHER_PATH)
