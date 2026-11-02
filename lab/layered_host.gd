class_name LayeredHost
extends Control

var _stack: SceneStack = SceneStack.new()
var _pending: Array[SceneRequest] = []

@onready var _content: Control = $Content


func _ready() -> void:
	_boot()
	_flush()


func _process(_delta: float) -> void:
	_flush()


## Override in subclasses to enqueue the first scene.
func _boot() -> void:
	pass


## Override in game hosts nested under the lab (return to launcher instead of quitting).
func _on_quit_requested() -> void:
	get_tree().quit()


func submit(req: SceneRequest) -> void:
	_pending.append(req)


## Sync Content children to match stack paths (bottom → top). Public for GUT.
func sync_layers(desired: Array[String]) -> void:
	_trim_mismatched_prefix(desired)
	while _content.get_child_count() < desired.size():
		var index := _content.get_child_count()
		_instance_layer(desired[index])
	_apply_process_modes()


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
			_on_quit_requested()
			return
	sync_layers(_stack.paths())


func _trim_mismatched_prefix(desired: Array[String]) -> void:
	var keep := 0
	var child_count := _content.get_child_count()
	while keep < child_count and keep < desired.size():
		var child: Node = _content.get_child(keep)
		if str(child.get_meta("scene_path", "")) != desired[keep]:
			break
		keep += 1
	while _content.get_child_count() > keep:
		var top: Node = _content.get_child(_content.get_child_count() - 1)
		_content.remove_child(top)
		top.free()


func _instance_layer(path: String) -> void:
	if path.is_empty():
		return
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("Failed to load scene: %s" % path)
		return
	var node: Node = packed.instantiate()
	node.set_meta("scene_path", path)
	_content.add_child(node)


func _apply_process_modes() -> void:
	var count := _content.get_child_count()
	for i in count:
		var child: Node = _content.get_child(i)
		if i < count - 1:
			child.process_mode = Node.PROCESS_MODE_DISABLED
		else:
			child.process_mode = Node.PROCESS_MODE_INHERIT
