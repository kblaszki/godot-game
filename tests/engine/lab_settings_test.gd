extends "res://addons/gut/test.gd"


func test_defaults() -> void:
	var settings := LabSettings.new()
	assert_eq(settings.mode, LabSettings.MODE_WINDOWED)
	assert_eq(settings.resolution, Vector2i(1280, 720))


func test_normalize_mode() -> void:
	assert_eq(LabSettings.normalize_mode("fullscreen"), LabSettings.MODE_FULLSCREEN)
	assert_eq(LabSettings.normalize_mode("windowed"), LabSettings.MODE_WINDOWED)
	assert_eq(LabSettings.normalize_mode("other"), LabSettings.MODE_WINDOWED)


func test_normalize_resolution_known_and_unknown() -> void:
	assert_eq(LabSettings.normalize_resolution(Vector2i(1600, 900)), Vector2i(1600, 900))
	assert_eq(LabSettings.normalize_resolution(Vector2i(1920, 1080)), Vector2i(1920, 1080))
	assert_eq(LabSettings.normalize_resolution(Vector2i(800, 600)), Vector2i(1280, 720))


func test_duplicate_settings() -> void:
	var original := LabSettings.new(LabSettings.MODE_FULLSCREEN, Vector2i(1920, 1080))
	var copy := original.duplicate_settings()
	assert_eq(copy.mode, LabSettings.MODE_FULLSCREEN)
	assert_eq(copy.resolution, Vector2i(1920, 1080))
	assert_ne(copy, original)
