class_name WindowApplier
extends RefCounted


static func apply(settings: LabSettings, window: Window) -> void:
	var normalized := settings.duplicate_settings()
	normalized.mode = LabSettings.normalize_mode(normalized.mode)
	normalized.resolution = LabSettings.normalize_resolution(normalized.resolution)
	if normalized.mode == LabSettings.MODE_FULLSCREEN:
		window.mode = Window.MODE_FULLSCREEN
		return
	window.mode = Window.MODE_WINDOWED
	window.size = normalized.resolution
