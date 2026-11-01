class_name SceneRequest
extends RefCounted

enum Kind { PUSH, POP, REPLACE, QUIT }

var kind: Kind
var scene_path: String = ""


static func push(path: String) -> SceneRequest:
	return _make(Kind.PUSH, path)


static func pop() -> SceneRequest:
	return _make(Kind.POP)


static func replace(path: String) -> SceneRequest:
	return _make(Kind.REPLACE, path)


static func quit() -> SceneRequest:
	return _make(Kind.QUIT)


static func _make(request_kind: Kind, path: String = "") -> SceneRequest:
	var req := SceneRequest.new()
	req.kind = request_kind
	req.scene_path = path
	return req
