class_name GridwardBot
extends RefCounted

## Utility player for Meadow on Normal. One `act()` spends at most once, then
## may start a wave. Calls the public sim API only.
##
## Map geometry is `GridwardCatalog.build_meadow()`. Upgrade prices use
## `GridwardSim.upgrade_cost` and a Normal `GridwardConfig`, matching the sim
## Meadow constructs for itself.

## Bolts placed before the first upgrade. Also the defense bar for starting.
const EARLY_TOWERS := 2
## Stop buying new towers after this many are down.
const MAX_TOWERS := 6
## Upgrade only when gold is above this multiple of the next tier cost.
const UPGRADE_RICH_FACTOR := 1.5
## Ignore a cell that adds less uncovered path than this, in cells.
const MIN_UNIQUE_CELLS := 2.0
## Bolt scores higher until this many towers exist, and on the teach waves.
const EARLY_BOLT_COUNT := 3
const EARLY_BOLT_WAVES := 2
const BOLT_EARLY_WEIGHT := 1.35
const BOLT_ID: StringName = &"bolt"
const _SAMPLE_STEP := 0.25

var _sim: GridwardSim
var _catalog: GridwardCatalog
var _map: MapDef
var _config: GridwardConfig
var _candidates: Array[Vector2i] = []
var _samples: PackedVector2Array = PackedVector2Array()
var _sample_lengths: PackedFloat32Array = PackedFloat32Array()
## Last gold/tower-count pair that had no legal cell. Skips repeat scans.
var _scan_gold := -1
var _scan_towers := -1


func _init(sim: GridwardSim, catalog: GridwardCatalog) -> void:
	_sim = sim
	_catalog = catalog
	_map = GridwardCatalog.build_meadow()
	_config = GridwardConfig.new()
	_cache_candidates()
	_cache_samples()


## Place, upgrade, or start the pending wave. No-op outside BUILD and WAVE.
func act() -> void:
	var phase := _sim.get_phase()
	if phase != GridwardSim.Phase.BUILD and phase != GridwardSim.Phase.WAVE:
		return
	if _sim.get_towers().size() < EARLY_TOWERS and _try_place():
		return
	if _try_upgrade():
		return
	if _can_consider_place() and _try_place():
		return
	if phase == GridwardSim.Phase.BUILD:
		_sim.start_wave()


func _try_upgrade() -> bool:
	var towers := _sim.get_towers()
	if towers.is_empty():
		return false
	var gold := _sim.get_gold()
	var cheapest := _cheapest_upgrade_cost(towers)
	if cheapest < 0 or float(gold) <= UPGRADE_RICH_FACTOR * float(cheapest):
		return false
	var best_id := -1
	var best_tier := _config.max_tier + 1
	var best_cover := -1.0
	for tower in towers:
		var state := tower as TowerState
		if state.tier >= _config.max_tier:
			continue
		var cost := _next_cost(state)
		if float(gold) <= UPGRADE_RICH_FACTOR * float(cost):
			continue
		var cover := GridwardSim.path_coverage_length(_map.waypoints, Vector2(state.cell), state.range)
		if _prefers_upgrade(state, cover, best_id, best_tier, best_cover):
			best_id = state.id
			best_tier = state.tier
			best_cover = cover
	if best_id < 0:
		return false
	return _sim.upgrade_tower(best_id)


func _prefers_upgrade(state: TowerState, cover: float, best_id: int, best_tier: int, best_cover: float) -> bool:
	if best_id < 0 or state.tier < best_tier:
		return true
	if state.tier > best_tier:
		return false
	if cover > best_cover:
		return true
	return is_equal_approx(cover, best_cover) and state.id < best_id


func _can_consider_place() -> bool:
	var count := _sim.get_towers().size()
	if count >= MAX_TOWERS or count < EARLY_TOWERS:
		return false
	if _sim.get_gold() < _cheapest_tower_cost():
		return false
	return not _holding_for_upgrade()


## Gold already pays for an upgrade and has not cleared the 1.5× line.
## Hold it instead of buying another tower.
func _holding_for_upgrade() -> bool:
	var towers := _sim.get_towers()
	var cheapest := _cheapest_upgrade_cost(towers)
	if cheapest < 0:
		return false
	var gold := float(_sim.get_gold())
	if gold < float(cheapest):
		return false
	return gold <= UPGRADE_RICH_FACTOR * float(cheapest)


func _try_place() -> bool:
	var gold := _sim.get_gold()
	var count := _sim.get_towers().size()
	if gold == _scan_gold and count == _scan_towers:
		return false
	if _search_and_place():
		_scan_gold = -1
		_scan_towers = -1
		return true
	_scan_gold = gold
	_scan_towers = count
	return false


func _search_and_place() -> bool:
	var best_cell := Vector2i.ZERO
	var best_id: StringName = &""
	var best_score := 0.0
	var found := false
	var towers := _sim.get_towers()
	for tower_id in _tower_ids_to_score():
		var definition := _catalog.tower(tower_id)
		if definition == null or _sim.get_gold() < definition.cost:
			continue
		var weight := _type_weight(tower_id)
		for cell in _candidates:
			if _occupied(cell, towers):
				continue
			var unique := _unique_length(Vector2(cell), definition.range, towers)
			if unique < MIN_UNIQUE_CELLS:
				continue
			var score := unique * weight
			if not found or score > best_score:
				found = true
				best_score = score
				best_cell = cell
				best_id = tower_id
	if not found:
		return false
	return _sim.place_tower(best_cell, best_id) >= 0


func _tower_ids_to_score() -> Array[StringName]:
	var ids: Array[StringName] = []
	if _prefer_bolt() and _map.unlocked_towers.has(BOLT_ID):
		var bolt := _catalog.tower(BOLT_ID)
		if bolt != null and _sim.get_gold() >= bolt.cost:
			ids.append(BOLT_ID)
			return ids
	for tower_id in _map.unlocked_towers:
		ids.append(tower_id)
	return ids


func _prefer_bolt() -> bool:
	return (
		_sim.get_towers().size() < EARLY_BOLT_COUNT
		or _sim.get_wave_index() <= EARLY_BOLT_WAVES
	)


func _type_weight(tower_id: StringName) -> float:
	if tower_id == BOLT_ID and _prefer_bolt():
		return BOLT_EARLY_WEIGHT
	return 1.0


func _unique_length(origin: Vector2, attack_range: float, towers: Array) -> float:
	if towers.is_empty():
		return GridwardSim.path_coverage_length(_map.waypoints, origin, attack_range)
	var total := 0.0
	var radius_sq := attack_range * attack_range
	for i in _samples.size():
		var point := _samples[i]
		if origin.distance_squared_to(point) > radius_sq:
			continue
		if _covered(point, towers):
			continue
		total += _sample_lengths[i]
	return total


func _covered(point: Vector2, towers: Array) -> bool:
	for tower in towers:
		var state := tower as TowerState
		var radius := state.range
		if point.distance_squared_to(Vector2(state.cell)) <= radius * radius:
			return true
	return false


func _occupied(cell: Vector2i, towers: Array) -> bool:
	for tower in towers:
		var state := tower as TowerState
		if state.cell == cell:
			return true
	return false


func _cheapest_upgrade_cost(towers: Array) -> int:
	var best := -1
	for tower in towers:
		var state := tower as TowerState
		if state.tier >= _config.max_tier:
			continue
		var cost := _next_cost(state)
		if best < 0 or cost < best:
			best = cost
	return best


func _next_cost(state: TowerState) -> int:
	return GridwardSim.upgrade_cost(
		state.base_cost,
		state.tier,
		_config.upgrade_cost_factor,
		_config.upgrade_cost_growth
	)


func _cheapest_tower_cost() -> int:
	var best := -1
	for tower_id in _map.unlocked_towers:
		var definition := _catalog.tower(tower_id)
		if definition == null:
			continue
		if best < 0 or definition.cost < best:
			best = definition.cost
	if best < 0:
		return 1000000000
	return best


func _cache_candidates() -> void:
	var pad := 4
	var seen := {}
	for cell in _map.path_cells():
		for y in range(cell.y - pad, cell.y + pad + 1):
			for x in range(cell.x - pad, cell.x + pad + 1):
				var candidate := Vector2i(x, y)
				if not _map.is_buildable(candidate):
					continue
				var key := candidate.y * _map.width + candidate.x
				if seen.has(key):
					continue
				seen[key] = true
				_candidates.append(candidate)
	_candidates.sort_custom(_cell_before)


func _cache_samples() -> void:
	var points := _map.waypoints
	for i in range(points.size() - 1):
		var start: Vector2 = points[i]
		var finish: Vector2 = points[i + 1]
		var delta := finish - start
		var length := delta.length()
		if length <= 0.0000001:
			continue
		var traveled := 0.0
		while traveled < length:
			var remain := length - traveled
			var piece := _SAMPLE_STEP if remain > _SAMPLE_STEP else remain
			var mid := start + delta * ((traveled + piece * 0.5) / length)
			_samples.append(mid)
			_sample_lengths.append(piece)
			traveled += piece


static func _cell_before(a: Vector2i, b: Vector2i) -> bool:
	if a.y == b.y:
		return a.x < b.x
	return a.y < b.y
