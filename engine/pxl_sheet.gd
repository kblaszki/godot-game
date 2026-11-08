class_name PxlSheet
extends RefCounted

## Parses TexturePacker-hash / Aseprite-style JSON written by the vendored pxl CLI.
## No FileAccess — callers pass JSON text. Default frame duration when omitted: 100 ms.

const DEFAULT_DURATION_MS := 100

var _valid: bool = false
var _names: PackedStringArray = PackedStringArray()
var _rects: Dictionary = {} ## StringName -> Rect2i
var _durations: Dictionary = {} ## StringName -> int
var _tags: Dictionary = {} ## StringName -> PackedStringArray


static func parse(json_text: String) -> PxlSheet:
	var sheet := PxlSheet.new()
	sheet._parse(json_text)
	return sheet


func is_valid() -> bool:
	return _valid


func frame_names() -> PackedStringArray:
	return _names.duplicate()


func frame_rect(name: StringName) -> Rect2i:
	if not _rects.has(name):
		return Rect2i()
	return _rects[name] as Rect2i


func frame_duration_ms(name: StringName) -> int:
	if not _durations.has(name):
		return DEFAULT_DURATION_MS
	return int(_durations[name])


func tag_frames(tag: StringName) -> PackedStringArray:
	if not _tags.has(tag):
		return PackedStringArray()
	return (_tags[tag] as PackedStringArray).duplicate()


func _parse(json_text: String) -> void:
	_valid = false
	_names = PackedStringArray()
	_rects.clear()
	_durations.clear()
	_tags.clear()
	var data: Variant = JSON.parse_string(json_text)
	if typeof(data) != TYPE_DICTIONARY:
		return
	var root: Dictionary = data
	if not root.has("frames") or typeof(root["frames"]) != TYPE_DICTIONARY:
		return
	var frames: Dictionary = root["frames"]
	for key in frames.keys():
		var entry: Variant = frames[key]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var entry_dict: Dictionary = entry
		if not entry_dict.has("frame") or typeof(entry_dict["frame"]) != TYPE_DICTIONARY:
			continue
		var fr: Dictionary = entry_dict["frame"]
		if not (fr.has("x") and fr.has("y") and fr.has("w") and fr.has("h")):
			continue
		var name := StringName(str(key))
		_names.append(String(name))
		_rects[name] = Rect2i(int(fr["x"]), int(fr["y"]), int(fr["w"]), int(fr["h"]))
		if entry_dict.has("duration"):
			_durations[name] = int(entry_dict["duration"])
		else:
			_durations[name] = DEFAULT_DURATION_MS
	if _names.is_empty():
		return
	if root.has("meta") and typeof(root["meta"]) == TYPE_DICTIONARY:
		_parse_tags(root["meta"] as Dictionary)
	_valid = true


func _parse_tags(meta: Dictionary) -> void:
	if not meta.has("frameTags") or typeof(meta["frameTags"]) != TYPE_ARRAY:
		return
	var tags: Array = meta["frameTags"]
	for tag_var in tags:
		if typeof(tag_var) != TYPE_DICTIONARY:
			continue
		var tag: Dictionary = tag_var
		if not tag.has("name"):
			continue
		var tag_name := StringName(str(tag["name"]))
		var from_i := int(tag.get("from", 0))
		var to_i := int(tag.get("to", from_i))
		if from_i < 0:
			from_i = 0
		if to_i >= _names.size():
			to_i = _names.size() - 1
		if to_i < from_i:
			continue
		var list := PackedStringArray()
		for i in range(from_i, to_i + 1):
			list.append(_names[i])
		_tags[tag_name] = list
