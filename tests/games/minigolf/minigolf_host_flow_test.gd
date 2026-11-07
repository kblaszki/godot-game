extends GutTest

const HOST_PATH := "res://games/minigolf/app/host.tscn"
const MENU_PATH := "res://games/minigolf/app/menu.tscn"
const SETUP_PATH := "res://games/minigolf/app/setup.tscn"
const PLAY_PATH := "res://games/minigolf/app/play.tscn"
const PAUSE_PATH := "res://games/minigolf/app/pause_menu.tscn"


func test_boot_should_show_menu() -> void:
	var host: Node = load(HOST_PATH).instantiate()
	add_child_autofree(host)
	await wait_frames(1)
	var content: Node = host.get_node("Content")
	assert_eq(content.get_child_count(), 1)
	assert_eq(str(content.get_child(0).get_meta("scene_path")), MENU_PATH)


func test_sync_layers_should_keep_play_alive_across_pause() -> void:
	var host: Node = load(HOST_PATH).instantiate()
	add_child_autofree(host)
	await wait_frames(1)
	var content: Node = host.get_node("Content")
	host.sync_layers([PLAY_PATH] as Array[String])
	assert_eq(content.get_child_count(), 1)
	var play: Node = content.get_child(0)
	assert_eq(str(play.get_meta("scene_path")), PLAY_PATH)

	host.sync_layers([PLAY_PATH, PAUSE_PATH] as Array[String])
	assert_eq(content.get_child_count(), 2)
	assert_true(is_instance_valid(play))
	assert_eq(play.process_mode, Node.PROCESS_MODE_DISABLED)

	host.sync_layers([PLAY_PATH] as Array[String])
	assert_eq(content.get_child_count(), 1)
	assert_eq(play.process_mode, Node.PROCESS_MODE_INHERIT)


func test_submit_should_reach_setup_then_play() -> void:
	var host: Node = load(HOST_PATH).instantiate()
	add_child_autofree(host)
	await wait_frames(1)
	var content: Node = host.get_node("Content")
	host.submit(SceneRequest.replace(SETUP_PATH))
	host._flush()
	assert_eq(str(content.get_child(0).get_meta("scene_path")), SETUP_PATH)
	host.submit(SceneRequest.replace(PLAY_PATH))
	host._flush()
	assert_eq(str(content.get_child(0).get_meta("scene_path")), PLAY_PATH)
