class_name SettingsStore
extends RefCounted

const HEADER := "gg-settings 1"
const DEFAULT_PATH := "user://settings.txt"


static func load(path: String = DEFAULT_PATH) -> LabSettings:
	if not FileAccess.file_exists(path):
		return LabSettings.new()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return LabSettings.new()
	var text := file.get_as_text()
	file.close()
	var parsed := _parse(text)
	if parsed == null:
		return LabSettings.new()
	return parsed


static func save(path: String, settings: LabSettings) -> bool:
	var base_dir := path.get_base_dir()
	if not base_dir.is_empty():
		var abs_dir := ProjectSettings.globalize_path(base_dir)
		var mk_err := DirAccess.make_dir_recursive_absolute(abs_dir)
		if mk_err != OK and not DirAccess.dir_exists_absolute(abs_dir):
			return false
	var tmp_path := path + ".tmp"
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(_serialize(settings))
	file.close()
	var abs_tmp := ProjectSettings.globalize_path(tmp_path)
	var abs_path := ProjectSettings.globalize_path(path)
	var rename_err := DirAccess.rename_absolute(abs_tmp, abs_path)
	if rename_err != OK:
		DirAccess.remove_absolute(abs_path)
		rename_err = DirAccess.rename_absolute(abs_tmp, abs_path)
	if rename_err != OK:
		DirAccess.remove_absolute(abs_tmp)
		return false
	return true


static func _serialize(settings: LabSettings) -> String:
	var mode := LabSettings.normalize_mode(settings.mode)
	var resolution := LabSettings.normalize_resolution(settings.resolution)
	var lines: PackedStringArray = [
		HEADER,
		"mode=%s" % mode,
		"resolution=%dx%d" % [resolution.x, resolution.y],
	]
	return "\n".join(lines) + "\n"


static func _parse(text: String) -> LabSettings:
	var lines := text.strip_edges().split("\n", false)
	if lines.is_empty() or lines[0] != HEADER:
		return null
	var mode := LabSettings.MODE_WINDOWED
	var resolution := LabSettings.RESOLUTIONS[0]
	var saw_mode := false
	var saw_resolution := false
	for i in range(1, lines.size()):
		var line := lines[i].strip_edges()
		if line.is_empty():
			continue
		var parts := line.split("=", false, 1)
		if parts.size() != 2:
			return null
		var key := parts[0].strip_edges()
		var value := parts[1].strip_edges()
		match key:
			"mode":
				if value != LabSettings.MODE_WINDOWED and value != LabSettings.MODE_FULLSCREEN:
					return null
				mode = value
				saw_mode = true
			"resolution":
				var dims := value.split("x", false, 1)
				if dims.size() != 2:
					return null
				if not dims[0].is_valid_int() or not dims[1].is_valid_int():
					return null
				resolution = LabSettings.normalize_resolution(
					Vector2i(int(dims[0]), int(dims[1]))
				)
				saw_resolution = true
			_:
				return null
	if not saw_mode or not saw_resolution:
		return null
	return LabSettings.new(mode, resolution)
