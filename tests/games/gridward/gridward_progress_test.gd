extends GutTest

const PATH := "user://gridward/test_progress_round_trip.txt"


func before_each() -> void:
	_wipe()


func after_each() -> void:
	_wipe()


func test_progress_round_trip() -> void:
	var missing := GridwardProgressStore.load(PATH)
	assert_eq(missing.version, GridwardProgress.VERSION)
	assert_true(missing.is_unlocked(GridwardCatalog.MEADOW))
	assert_false(missing.is_unlocked(GridwardCatalog.BEND))

	var progress := GridwardProgress.new()
	var earned := progress.record_victory(GridwardCatalog.MEADOW, GridwardConfig.DIFF_NORMAL, 16)
	assert_eq(earned, 3)
	earned = progress.record_victory(GridwardCatalog.MEADOW, GridwardConfig.DIFF_NORMAL, 4)
	assert_eq(earned, 1)
	assert_eq(progress.stars_for(GridwardCatalog.MEADOW, GridwardConfig.DIFF_NORMAL), 3)
	assert_eq(progress.record_victory(GridwardCatalog.MEADOW, GridwardConfig.DIFF_EASY, 9), 2)
	assert_true(progress.is_unlocked(GridwardCatalog.BEND))
	assert_false(progress.is_unlocked(GridwardCatalog.SKYREACH))

	assert_true(GridwardProgressStore.save(PATH, progress))
	var loaded := GridwardProgressStore.load(PATH)
	assert_eq(loaded.version, 1)
	assert_eq(loaded.stars_for(GridwardCatalog.MEADOW, GridwardConfig.DIFF_NORMAL), 3)
	assert_eq(loaded.stars_for(GridwardCatalog.MEADOW, GridwardConfig.DIFF_EASY), 2)
	assert_eq(loaded.stars_for(GridwardCatalog.MEADOW, GridwardConfig.DIFF_HARD), 0)
	assert_true(loaded.is_unlocked(GridwardCatalog.BEND))
	assert_false(loaded.is_unlocked(GridwardCatalog.CITADEL))


func test_migrate_v1_noop() -> void:
	assert_eq(GridwardProgressStore.CURRENT, GridwardProgress.VERSION)
	var data := {
		"version": 1,
		"cleared": {
			"meadow": {"easy": 1, "normal": 3, "hard": 0},
		},
	}
	var migrated := GridwardProgressStore.migrate(data)
	assert_eq(int(migrated["version"]), 1)
	var row: Dictionary = migrated["cleared"]["meadow"]
	assert_eq(int(row["easy"]), 1)
	assert_eq(int(row["normal"]), 3)
	assert_eq(int(row["hard"]), 0)
	var progress := GridwardProgress.new()
	progress.apply_state(migrated)
	assert_eq(progress.version, 1)
	assert_eq(progress.stars_for(&"meadow", &"easy"), 1)
	assert_eq(progress.stars_for(&"meadow", &"normal"), 3)
	assert_eq(progress.stars_for(&"meadow", &"hard"), 0)
	row["easy"] = 9
	assert_eq(int((data["cleared"] as Dictionary)["meadow"]["easy"]), 1)


func test_missing_or_corrupt_file_should_load_empty_progress() -> void:
	var missing := GridwardProgressStore.load(PATH)
	assert_eq(missing.stars_for(GridwardCatalog.MEADOW, GridwardConfig.DIFF_NORMAL), 0)
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string("not-a-header\nmeadow normal 3\n")
	file.close()
	var loaded := GridwardProgressStore.load(PATH)
	assert_eq(loaded.stars_for(GridwardCatalog.MEADOW, GridwardConfig.DIFF_NORMAL), 0)
	assert_false(loaded.is_unlocked(GridwardCatalog.BEND))


func _wipe() -> void:
	for p in [PATH, PATH + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
