extends "res://addons/gut/test.gd"

const PATH := "user://settings/test_settings_store.txt"


func before_each() -> void:
	_cleanup()


func after_each() -> void:
	_cleanup()


func test_load_missing_should_return_defaults() -> void:
	var settings := SettingsStore.load(PATH)
	assert_eq(settings.mode, LabSettings.MODE_WINDOWED)
	assert_eq(settings.resolution, Vector2i(1280, 720))


func test_save_and_load_round_trip() -> void:
	var settings := LabSettings.new(LabSettings.MODE_FULLSCREEN, Vector2i(1600, 900))
	assert_true(SettingsStore.save(PATH, settings))
	var loaded := SettingsStore.load(PATH)
	assert_eq(loaded.mode, LabSettings.MODE_FULLSCREEN)
	assert_eq(loaded.resolution, Vector2i(1600, 900))


func test_corrupt_file_should_load_defaults() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("not-a-header\nmode=windowed\n")
	file.close()
	var loaded := SettingsStore.load(PATH)
	assert_eq(loaded.mode, LabSettings.MODE_WINDOWED)
	assert_eq(loaded.resolution, Vector2i(1280, 720))


func test_unknown_resolution_normalizes_on_load() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("gg-settings 1\nmode=windowed\nresolution=800x600\n")
	file.close()
	var loaded := SettingsStore.load(PATH)
	assert_eq(loaded.mode, LabSettings.MODE_WINDOWED)
	assert_eq(loaded.resolution, Vector2i(1280, 720))


func test_invalid_mode_should_load_defaults() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("gg-settings 1\nmode=borderless\nresolution=1280x720\n")
	file.close()
	var loaded := SettingsStore.load(PATH)
	assert_eq(loaded.mode, LabSettings.MODE_WINDOWED)
	assert_eq(loaded.resolution, Vector2i(1280, 720))


func _cleanup() -> void:
	for p in [PATH, PATH + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
