extends "res://addons/gut/test.gd"


func test_same_seed_should_produce_same_sequence() -> void:
	var left := _draw(SeededRng.new(42))
	var right := _draw(SeededRng.new(42))
	assert_eq(left, right)


func test_different_seeds_should_differ() -> void:
	var left := _draw(SeededRng.new(1))
	var right := _draw(SeededRng.new(2))
	assert_ne(left, right)


func _draw(rng: SeededRng) -> Array:
	return [
		rng.randf(),
		rng.randi_range(-5, 20),
		rng.randf_range(0.25, 4.5),
		rng.randf(),
	]
