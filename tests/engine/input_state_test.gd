extends "res://addons/gut/test.gd"


func test_held_and_edges_across_frames() -> void:
	var state := InputState.new()
	state.begin_frame()
	state.set_action(&"jump", true)
	assert_true(state.is_action_pressed(&"jump"))
	assert_true(state.is_action_just_pressed(&"jump"))
	assert_false(state.is_action_just_released(&"jump"))

	state.begin_frame()
	state.set_action(&"jump", true)
	assert_true(state.is_action_pressed(&"jump"))
	assert_false(state.is_action_just_pressed(&"jump"))
	assert_false(state.is_action_just_released(&"jump"))

	state.begin_frame()
	state.set_action(&"jump", false)
	assert_false(state.is_action_pressed(&"jump"))
	assert_false(state.is_action_just_pressed(&"jump"))
	assert_true(state.is_action_just_released(&"jump"))


func test_get_axis_from_held_actions() -> void:
	var state := InputState.new()
	state.begin_frame()
	state.set_action(&"left", false)
	state.set_action(&"right", false)
	assert_eq(state.get_axis(&"left", &"right"), 0.0)

	state.begin_frame()
	state.set_action(&"left", true)
	state.set_action(&"right", false)
	assert_eq(state.get_axis(&"left", &"right"), -1.0)

	state.begin_frame()
	state.set_action(&"left", true)
	state.set_action(&"right", true)
	assert_eq(state.get_axis(&"left", &"right"), 0.0)

	state.begin_frame()
	state.set_action(&"left", false)
	state.set_action(&"right", true)
	assert_eq(state.get_axis(&"left", &"right"), 1.0)


func test_unknown_action_is_not_pressed() -> void:
	var state := InputState.new()
	assert_false(state.is_action_pressed(&"missing"))
	assert_false(state.is_action_just_pressed(&"missing"))
	assert_false(state.is_action_just_released(&"missing"))
