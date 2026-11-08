class_name GridwardProgressStore
extends RefCounted

## Text save for GridwardProgress. FileAccess stays in app/.
## Header is "gg-gridward-progress <version>". Later lines are "map difficulty stars".

const HEADER_PREFIX := "gg-gridward-progress"
const CURRENT := 1
const DEFAULT_PATH := "user://gridward/progress.txt"


static func load(path: String = DEFAULT_PATH) -> GridwardProgress:
	var progress := GridwardProgress.new()
	if not FileAccess.file_exists(path):
		return progress
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return progress
	var text := file.get_as_text()
	file.close()
	var parsed := _parse(text)
	if parsed.is_empty():
		return progress
	progress.apply_state(migrate(parsed))
	return progress


static func save(path: String, progress: GridwardProgress) -> bool:
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
	file.store_string(_serialize(progress))
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


## Copies data forward until CURRENT. Version 1 has no field changes.
static func migrate(data: Dictionary) -> Dictionary:
	var copy: Dictionary = data.duplicate(true)
	var version := int(copy.get("version", 1))
	if version < 1:
		version = 1
		copy["version"] = version
	while version < CURRENT:
		copy = _migrate_step(copy, version)
		version += 1
		copy["version"] = version
	return copy


static func _migrate_step(data: Dictionary, from_version: int) -> Dictionary:
	if int(data.get("version", 0)) != from_version:
		data["version"] = from_version
	return data


static func _serialize(progress: GridwardProgress) -> String:
	var state := progress.capture_state()
	var lines: PackedStringArray = ["%s %d" % [HEADER_PREFIX, int(state["version"])]]
	var rows: Dictionary = state["cleared"]
	var map_ids: Array = rows.keys()
	map_ids.sort()
	for map_key in map_ids:
		var row: Dictionary = rows[map_key]
		for difficulty in ["easy", "normal", "hard"]:
			var stars := int(row.get(difficulty, 0))
			if stars > 0:
				lines.append("%s %s %d" % [str(map_key), difficulty, stars])
	return "\n".join(lines) + "\n"


static func _parse(text: String) -> Dictionary:
	var lines := text.strip_edges().split("\n", false)
	if lines.is_empty():
		return {}
	var header := lines[0].strip_edges().split(" ", false)
	if header.size() != 2 or header[0] != HEADER_PREFIX:
		return {}
	if not header[1].is_valid_int():
		return {}
	var version := int(header[1])
	if version < 1:
		return {}
	var rows := {}
	for i in range(1, lines.size()):
		var line := lines[i].strip_edges()
		if line.is_empty():
			continue
		var parts := line.split(" ", false)
		if parts.size() != 3:
			return {}
		var map_id := parts[0]
		var difficulty := parts[1]
		if map_id.is_empty():
			return {}
		if difficulty != "easy" and difficulty != "normal" and difficulty != "hard":
			return {}
		if not parts[2].is_valid_int():
			return {}
		var stars := int(parts[2])
		if stars < 1 or stars > 3:
			return {}
		if not rows.has(map_id):
			rows[map_id] = {"easy": 0, "normal": 0, "hard": 0}
		rows[map_id][difficulty] = stars
	return {"version": version, "cleared": rows}
