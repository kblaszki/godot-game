extends "res://addons/gut/test.gd"


func test_square_fit_should_fill() -> void:
	var result := ViewFit.compute(Vector2(100, 100), Vector2(200, 200))
	assert_eq(result["scale"], 2.0)
	assert_eq(result["offset"], Vector2.ZERO)


func test_letterbox_when_viewport_wider() -> void:
	var result := ViewFit.compute(Vector2(100, 100), Vector2(200, 100))
	assert_eq(result["scale"], 1.0)
	assert_eq(result["offset"], Vector2(50, 0))


func test_pillarbox_when_viewport_taller() -> void:
	var result := ViewFit.compute(Vector2(100, 100), Vector2(100, 200))
	assert_eq(result["scale"], 1.0)
	assert_eq(result["offset"], Vector2(0, 50))


func test_degenerate_sizes_should_return_identity() -> void:
	var result := ViewFit.compute(Vector2.ZERO, Vector2(1280, 720))
	assert_eq(result["scale"], 1.0)
	assert_eq(result["offset"], Vector2.ZERO)
	result = ViewFit.compute(Vector2(800, 450), Vector2.ZERO)
	assert_eq(result["scale"], 1.0)
	assert_eq(result["offset"], Vector2.ZERO)
