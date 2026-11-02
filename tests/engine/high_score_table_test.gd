extends "res://addons/gut/test.gd"


func test_insert_should_rank_descending_and_keep_older_ties() -> void:
	var table := HighScoreTable.new(3)
	assert_eq(table.insert(10), 0)
	assert_eq(table.insert(20), 0)
	assert_eq(table.insert(20), 1)
	assert_eq(table.entries(), [20, 20, 10])
	assert_false(table.qualifies(5))
	assert_eq(table.insert(5), -1)
	assert_true(table.qualifies(11))
	assert_eq(table.insert(11), 2)
	assert_eq(table.entries(), [20, 20, 11])


func test_zero_capacity_rejects_all() -> void:
	var table := HighScoreTable.new(0)
	assert_false(table.qualifies(100))
	assert_eq(table.insert(100), -1)
	assert_eq(table.entries(), [])
