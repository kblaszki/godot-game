class_name GridwardProgress
extends RefCounted

## Campaign clears. Stars are per map and difficulty. No filesystem.

const VERSION := 1

var version: int = VERSION
## map id -> difficulty id -> star count (1–3). Missing entries are 0 stars.
var cleared: Dictionary = {}


func stars_for(map_id: StringName, difficulty: StringName) -> int:
	if not cleared.has(map_id):
		return 0
	var row: Dictionary = cleared[map_id]
	return int(row.get(difficulty, 0))


func best_stars(map_id: StringName) -> int:
	var best := 0
	for difficulty in GridwardConfig.DIFFICULTIES:
		best = maxi(best, stars_for(map_id, difficulty))
	return best


## Meadow is open. Each later map needs at least one star on the map before it.
func is_unlocked(map_id: StringName) -> bool:
	var order := GridwardCatalog.MAP_IDS
	var index := order.find(map_id)
	if index <= 0:
		return index == 0
	return best_stars(order[index - 1]) >= 1


## Lives left at victory. Defaults match spec §9. Returns the stars for this clear.
static func stars_from_lives(lives: int, three_at: int = 15, two_at: int = 8) -> int:
	if lives >= three_at:
		return 3
	if lives >= two_at:
		return 2
	if lives > 0:
		return 1
	return 0


## Stores the best star count for that difficulty. Returns the stars earned now.
func record_victory(
	map_id: StringName,
	difficulty: StringName,
	lives: int,
	three_at: int = 15,
	two_at: int = 8
) -> int:
	var earned := stars_from_lives(lives, three_at, two_at)
	if not GridwardConfig.DIFFICULTIES.has(difficulty):
		return earned
	var kept := maxi(earned, stars_for(map_id, difficulty))
	if kept > 0:
		_set_stars(map_id, difficulty, kept)
	return earned


func capture_state() -> Dictionary:
	var rows := {}
	for map_key in cleared.keys():
		var map_id := StringName(map_key)
		var row: Dictionary = cleared[map_key]
		var out := {"easy": 0, "normal": 0, "hard": 0}
		for difficulty in GridwardConfig.DIFFICULTIES:
			out[String(difficulty)] = clampi(int(row.get(difficulty, 0)), 0, 3)
		rows[String(map_id)] = out
	return {"version": version, "cleared": rows}


## Caller migrates and validates first. Replaces cleared.
func apply_state(data: Dictionary) -> void:
	version = int(data.get("version", VERSION))
	cleared.clear()
	var rows: Dictionary = data.get("cleared", {})
	for map_key in rows.keys():
		var row: Dictionary = rows[map_key]
		var map_id := StringName(str(map_key))
		for difficulty in GridwardConfig.DIFFICULTIES:
			var stars := int(row.get(String(difficulty), 0))
			if stars < 1:
				continue
			_set_stars(map_id, difficulty, mini(stars, 3))


func _set_stars(map_id: StringName, difficulty: StringName, stars: int) -> void:
	if not cleared.has(map_id):
		cleared[map_id] = {}
	var row: Dictionary = cleared[map_id]
	row[difficulty] = stars
	cleared[map_id] = row
