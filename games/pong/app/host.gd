extends Control

const MENU_PATH := "res://games/pong/app/main_menu.tscn"

var _stack: SceneStack = SceneStack.new()
var _pending: Array[SceneRequest] = []
var _current_path: String = ""

@onready var _content: Control = $Content


func _ready() -> void:
	var config := PongConfig.new()
	get_window().size = Vector2i(int(config.court_width), int(config.court_height))
	submit(SceneRequest.replace(MENU_PATH))
	_flush()


func _process(_delta: float) -> void:
	_flush()


func submit(req: SceneRequest) -> void:
	_pending.append(req)


func _flush() -> void:
	if _pending.is_empty():
		return
	var batch: Array[SceneRequest] = _pending.duplicate()
	_pending.clear()
	for req: SceneRequest in batch:
		_stack.request(req)
	var applied: Array = _stack.apply()
	for item in applied:
		var req := item as SceneRequest
		if req != null and req.kind == SceneRequest.Kind.QUIT:
			get_tree().quit()
			return
	var path := _stack.peek()
	if path == _current_path:
		return
	_swap(path)


func _swap(path: String) -> void:
	for child: Node in _content.get_children():
		_content.remove_child(child)
		child.free()
	_current_path = path
	if path.is_empty():
		return
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("Failed to load scene: %s" % path)
		return
	_content.add_child(packed.instantiate())
