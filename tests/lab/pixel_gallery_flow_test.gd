extends GutTest

const LAB_HOST_PATH := "res://lab/lab_host.tscn"
const LAUNCHER_PATH := "res://lab/launcher.tscn"
const GALLERY_PATH := "res://lab/pixel_gallery.tscn"


func test_gallery_should_load_sheet_and_cycle_variant() -> void:
	var lab: Node = load(LAB_HOST_PATH).instantiate()
	add_child_autofree(lab)
	await wait_frames(1)
	lab.submit(SceneRequest.replace(GALLERY_PATH))
	lab._flush()
	await wait_frames(1)
	var gallery: Node = lab.get_node("Content").get_child(0)
	assert_eq(str(gallery.get_meta("scene_path")), GALLERY_PATH)
	assert_eq(gallery.sheet_frame_count(), 9)
	var first: StringName = gallery.cycle_variant()
	assert_eq(String(first), "slime_red")
	var second: StringName = gallery.cycle_variant()
	assert_eq(String(second), "slime_blue")
	gallery._on_back_pressed()
	assert_eq(gallery.last_replace_path(), LAUNCHER_PATH)
	lab._flush()
	await wait_frames(1)
	assert_eq(str(lab.get_node("Content").get_child(0).get_meta("scene_path")), LAUNCHER_PATH)


func test_launcher_should_open_pixel_gallery() -> void:
	var lab: Node = load(LAB_HOST_PATH).instantiate()
	add_child_autofree(lab)
	await wait_frames(1)
	var launcher: Node = lab.get_node("Content").get_child(0)
	launcher._on_pixel_gallery_pressed()
	lab._flush()
	await wait_frames(1)
	assert_eq(str(lab.get_node("Content").get_child(0).get_meta("scene_path")), GALLERY_PATH)
