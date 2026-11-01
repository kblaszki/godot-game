extends "res://addons/gut/test.gd"


func test_sec_should_equal_one_sixtieth_of_a_second() -> void:
	assert_eq(FixedTick.SEC, 1.0 / 60.0)
