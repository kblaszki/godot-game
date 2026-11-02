extends "res://addons/gut/test.gd"


func test_apply_windowed_sets_mode_and_size() -> void:
	var window := Window.new()
	add_child_autofree(window)
	var settings := LabSettings.new(LabSettings.MODE_WINDOWED, Vector2i(1600, 900))
	WindowApplier.apply(settings, window)
	assert_eq(window.mode, Window.MODE_WINDOWED)
	assert_eq(window.size, Vector2i(1600, 900))


func test_apply_fullscreen_sets_mode_and_keeps_pref_resolution() -> void:
	var window := Window.new()
	add_child_autofree(window)
	window.size = Vector2i(800, 600)
	var settings := LabSettings.new(LabSettings.MODE_FULLSCREEN, Vector2i(1920, 1080))
	WindowApplier.apply(settings, window)
	assert_eq(window.mode, Window.MODE_FULLSCREEN)
	assert_eq(settings.resolution, Vector2i(1920, 1080))
