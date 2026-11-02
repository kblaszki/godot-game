extends GutTest

const LAB_HOST_PATH := "res://lab/lab_host.tscn"
const LAUNCHER_PATH := "res://lab/launcher.tscn"
const SETTINGS_PATH := "res://lab/settings.tscn"
const STORE_PATH := "user://settings.txt"


func before_each() -> void:
	_cleanup_store()


func after_each() -> void:
	_cleanup_store()


func test_launcher_settings_should_replace_and_back() -> void:
	var lab: Node = load(LAB_HOST_PATH).instantiate()
	add_child_autofree(lab)
	await wait_frames(1)
	var content: Node = lab.get_node("Content")
	assert_eq(str(content.get_child(0).get_meta("scene_path")), LAUNCHER_PATH)

	lab.submit(SceneRequest.replace(SETTINGS_PATH))
	lab._flush()
	await wait_frames(1)
	assert_eq(str(content.get_child(0).get_meta("scene_path")), SETTINGS_PATH)

	var settings_scene: Node = content.get_child(0)
	settings_scene._on_back_pressed()
	lab._flush()
	await wait_frames(1)
	assert_eq(str(content.get_child(0).get_meta("scene_path")), LAUNCHER_PATH)


func test_settings_resolution_change_should_persist() -> void:
	var lab: Node = load(LAB_HOST_PATH).instantiate()
	add_child_autofree(lab)
	await wait_frames(1)
	lab.submit(SceneRequest.replace(SETTINGS_PATH))
	lab._flush()
	await wait_frames(1)
	var settings_scene: Node = lab.get_node("Content").get_child(0)
	settings_scene._on_next_pressed()
	var loaded := SettingsStore.load(STORE_PATH)
	assert_eq(loaded.resolution, Vector2i(1600, 900))
	assert_eq(loaded.mode, LabSettings.MODE_WINDOWED)


func _cleanup_store() -> void:
	for p in [STORE_PATH, STORE_PATH + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
