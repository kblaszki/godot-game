class_name LabSettings
extends RefCounted

const MODE_WINDOWED := "windowed"
const MODE_FULLSCREEN := "fullscreen"

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]

var mode: String = MODE_WINDOWED
var resolution: Vector2i = RESOLUTIONS[0]


func _init(p_mode: String = MODE_WINDOWED, p_resolution: Vector2i = RESOLUTIONS[0]) -> void:
	mode = normalize_mode(p_mode)
	resolution = normalize_resolution(p_resolution)


static func normalize_mode(value: String) -> String:
	if value == MODE_FULLSCREEN:
		return MODE_FULLSCREEN
	return MODE_WINDOWED


static func normalize_resolution(value: Vector2i) -> Vector2i:
	for candidate in RESOLUTIONS:
		if candidate == value:
			return candidate
	return RESOLUTIONS[0]


func duplicate_settings() -> LabSettings:
	return LabSettings.new(mode, resolution)
