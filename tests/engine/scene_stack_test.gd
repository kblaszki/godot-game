extends GutTest


func test_request_should_leave_stack_unchanged_until_apply() -> void:
	var stack := SceneStack.new()
	stack.request(SceneRequest.push("res://menu.tscn"))
	assert_eq(stack.peek(), "")
	assert_eq(stack.depth(), 0)


func test_apply_should_push_path() -> void:
	var stack := SceneStack.new()
	stack.request(SceneRequest.push("res://menu.tscn"))
	var applied: Array = stack.apply()
	assert_eq(applied.size(), 1)
	assert_eq((applied[0] as SceneRequest).kind, SceneRequest.Kind.PUSH)
	assert_eq(stack.peek(), "res://menu.tscn")
	assert_eq(stack.depth(), 1)


func test_apply_should_replace_top() -> void:
	var stack := SceneStack.new()
	stack.request(SceneRequest.push("res://menu.tscn"))
	stack.request(SceneRequest.replace("res://play.tscn"))
	stack.apply()
	assert_eq(stack.peek(), "res://play.tscn")
	assert_eq(stack.depth(), 1)


func test_apply_should_pop_top() -> void:
	var stack := SceneStack.new()
	stack.request(SceneRequest.push("res://menu.tscn"))
	stack.request(SceneRequest.push("res://play.tscn"))
	stack.apply()
	stack.request(SceneRequest.pop())
	var applied: Array = stack.apply()
	assert_eq(applied.size(), 1)
	assert_eq((applied[0] as SceneRequest).kind, SceneRequest.Kind.POP)
	assert_eq(stack.peek(), "res://menu.tscn")
	assert_eq(stack.depth(), 1)


func test_apply_should_record_quit_and_keep_stack() -> void:
	var stack := SceneStack.new()
	stack.request(SceneRequest.push("res://menu.tscn"))
	stack.request(SceneRequest.quit())
	var applied: Array = stack.apply()
	assert_eq(applied.size(), 2)
	assert_eq((applied[1] as SceneRequest).kind, SceneRequest.Kind.QUIT)
	assert_eq((applied[1] as SceneRequest).scene_path, "")
	assert_eq(stack.peek(), "res://menu.tscn")
	assert_eq(stack.depth(), 1)


func test_apply_should_run_a_batch_in_order() -> void:
	var stack := SceneStack.new()
	stack.request(SceneRequest.push("res://menu.tscn"))
	stack.request(SceneRequest.push("res://play.tscn"))
	stack.request(SceneRequest.replace("res://pause.tscn"))
	stack.request(SceneRequest.pop())
	stack.request(SceneRequest.quit())
	var applied: Array = stack.apply()
	assert_eq(applied.size(), 5)
	assert_eq((applied[0] as SceneRequest).kind, SceneRequest.Kind.PUSH)
	assert_eq((applied[1] as SceneRequest).scene_path, "res://play.tscn")
	assert_eq((applied[2] as SceneRequest).kind, SceneRequest.Kind.REPLACE)
	assert_eq((applied[3] as SceneRequest).kind, SceneRequest.Kind.POP)
	assert_eq((applied[4] as SceneRequest).kind, SceneRequest.Kind.QUIT)
	assert_eq(stack.peek(), "res://menu.tscn")
	assert_eq(stack.depth(), 1)
	assert_eq(stack.apply().size(), 0)


func test_apply_should_ignore_pop_on_empty_stack() -> void:
	var stack := SceneStack.new()
	stack.request(SceneRequest.pop())
	var applied: Array = stack.apply()
	assert_eq(applied.size(), 1)
	assert_eq(stack.peek(), "")
	assert_eq(stack.depth(), 0)


func test_apply_should_push_when_replace_starts_empty() -> void:
	var stack := SceneStack.new()
	stack.request(SceneRequest.replace("res://menu.tscn"))
	stack.apply()
	assert_eq(stack.peek(), "res://menu.tscn")
	assert_eq(stack.depth(), 1)


func test_paths_should_return_full_stack_copy() -> void:
	var stack := SceneStack.new()
	assert_eq(stack.paths().size(), 0)
	stack.request(SceneRequest.push("res://menu.tscn"))
	stack.request(SceneRequest.push("res://play.tscn"))
	stack.apply()
	var snapshot: Array[String] = stack.paths()
	assert_eq(snapshot.size(), 2)
	assert_eq(snapshot[0], "res://menu.tscn")
	assert_eq(snapshot[1], "res://play.tscn")
	snapshot[0] = "res://mutated.tscn"
	assert_eq(stack.paths()[0], "res://menu.tscn")
	stack.request(SceneRequest.pop())
	stack.apply()
	assert_eq(stack.paths().size(), 1)
	assert_eq(stack.paths()[0], "res://menu.tscn")
	stack.request(SceneRequest.replace("res://other.tscn"))
	stack.apply()
	assert_eq(stack.paths().size(), 1)
	assert_eq(stack.paths()[0], "res://other.tscn")
