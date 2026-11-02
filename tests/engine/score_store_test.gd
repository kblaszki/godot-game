extends "res://addons/gut/test.gd"

const PATH := "user://scores/test_score_store.txt"


func before_each() -> void:
	_cleanup()


func after_each() -> void:
	_cleanup()


func test_load_missing_should_return_empty_table() -> void:
	var table := ScoreStore.load(PATH, 5)
	assert_eq(table.capacity(), 5)
	assert_eq(table.entries(), [])


func test_save_and_load_round_trip() -> void:
	var table := HighScoreTable.new(3)
	table.insert(5)
	table.insert(15)
	table.insert(10)
	assert_true(ScoreStore.save(PATH, table))
	var loaded := ScoreStore.load(PATH, 3)
	assert_eq(loaded.entries(), [15, 10, 5])


func test_corrupt_file_should_load_empty() -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("not-a-header\n1\n")
	file.close()
	var loaded := ScoreStore.load(PATH, 4)
	assert_eq(loaded.entries(), [])
	assert_eq(loaded.capacity(), 4)


func _cleanup() -> void:
	for p in [PATH, PATH + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
