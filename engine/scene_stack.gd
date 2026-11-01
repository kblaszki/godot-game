class_name SceneStack
extends RefCounted

var _paths: Array[String] = []
var _pending: Array[SceneRequest] = []


func request(req: SceneRequest) -> void:
	_pending.append(req)


func apply() -> Array:
	var batch: Array[SceneRequest] = _pending.duplicate()
	_pending.clear()
	var applied: Array = []
	for req: SceneRequest in batch:
		_apply_one(req)
		applied.append(req)
	return applied


func peek() -> String:
	if _paths.is_empty():
		return ""
	return _paths[_paths.size() - 1]


func depth() -> int:
	return _paths.size()


func _apply_one(req: SceneRequest) -> void:
	match req.kind:
		SceneRequest.Kind.PUSH:
			_paths.append(req.scene_path)
		SceneRequest.Kind.POP:
			if not _paths.is_empty():
				_paths.pop_back()
		SceneRequest.Kind.REPLACE:
			if not _paths.is_empty():
				_paths.pop_back()
			_paths.append(req.scene_path)
		SceneRequest.Kind.QUIT:
			pass
