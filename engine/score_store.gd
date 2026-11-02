class_name ScoreStore
extends RefCounted

const HEADER := "gg-highscores 1"


static func load(path: String, capacity: int) -> HighScoreTable:
	var table := HighScoreTable.new(capacity)
	if not FileAccess.file_exists(path):
		return table
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return table
	var text := file.get_as_text()
	file.close()
	var parsed := _parse(text, capacity)
	if parsed == null:
		return HighScoreTable.new(capacity)
	return parsed


static func save(path: String, table: HighScoreTable) -> bool:
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
	file.store_string(_serialize(table))
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


static func _serialize(table: HighScoreTable) -> String:
	var lines: PackedStringArray = [HEADER]
	for score in table.entries():
		lines.append(str(score))
	return "\n".join(lines) + "\n"


static func _parse(text: String, capacity: int) -> HighScoreTable:
	var lines := text.strip_edges().split("\n", false)
	if lines.is_empty() or lines[0] != HEADER:
		return null
	var table := HighScoreTable.new(capacity)
	for i in range(1, lines.size()):
		var line := lines[i].strip_edges()
		if line.is_empty():
			continue
		if not line.is_valid_int():
			return null
		var score := int(line)
		if score < 0:
			return null
		table.insert(score)
	return table
