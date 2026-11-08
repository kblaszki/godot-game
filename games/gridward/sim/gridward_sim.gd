class_name GridwardSim
extends RefCounted

## Headless match. Towers do not acquire or fire yet.

enum Phase { BUILD, WAVE, WAVE_CLEAR, VICTORY, DEFEAT }

var _map: MapDef
var _catalog: GridwardCatalog
var _config: GridwardConfig
var _rng: SeededRng
var _phase: Phase = Phase.BUILD
var _gold: int = 0
var _lives: int = 0
var _wave_index: int = 0
var _wave_tick: int = 0
var _next_enemy_id: int = 0
var _enemies: Array[EnemyState] = []
var _events: Array[Dictionary] = []
## Flat spawn list sorted by tick, then by schedule order.
var _spawns: Array[Dictionary] = []
var _spawn_cursor: int = 0


func _init(map: MapDef, catalog: GridwardCatalog, seed: int) -> void:
	_map = map
	_catalog = catalog
	_config = GridwardConfig.new()
	_rng = SeededRng.new(seed)
	_gold = map.starting_gold
	_lives = map.starting_lives
	_wave_index = 0
	_phase = Phase.BUILD
	if _lives <= 0:
		_phase = Phase.DEFEAT


func get_phase() -> int:
	return int(_phase)


func get_gold() -> int:
	return _gold


func get_lives() -> int:
	return _lives


func get_wave_index() -> int:
	return _wave_index


func start_wave() -> bool:
	if _phase != Phase.BUILD:
		return false
	if _lives <= 0:
		_phase = Phase.DEFEAT
		_events.append(GridwardEvents.defeat())
		return false
	if _wave_index < 0 or _wave_index >= _map.waves.size():
		return false
	_build_schedule(_map.waves[_wave_index])
	_wave_tick = 0
	_phase = Phase.WAVE
	_events.append(GridwardEvents.wave_started(_wave_index))
	return true


func step() -> void:
	if _phase == Phase.WAVE_CLEAR:
		_leave_wave_clear()
		return
	if _phase != Phase.WAVE:
		return
	_spawn_due()
	_move_enemies()
	_acquire_targets()
	if _phase == Phase.WAVE and _all_spawned() and _enemies.is_empty():
		_phase = Phase.WAVE_CLEAR
		_events.append(GridwardEvents.wave_cleared(_wave_index))
		return
	if _phase == Phase.WAVE:
		_wave_tick += 1


func drain_events() -> Array:
	var out := _events.duplicate()
	_events.clear()
	return out


func get_enemies() -> Array:
	var out: Array = []
	for enemy in _enemies:
		out.append(enemy)
	return out


func _build_schedule(wave: WaveDef) -> void:
	_spawns.clear()
	_spawn_cursor = 0
	var order := 0
	var jitter := _config.spawn_jitter_ticks
	for entry in wave.entries:
		var row: Dictionary = entry
		var count := int(row["count"])
		var spacing := int(row["spacing_ticks"])
		var delay := int(row["delay_ticks"])
		for i in count:
			var tick := delay + i * spacing
			if jitter > 0:
				tick += _rng.randi_range(-jitter, jitter)
				if tick < 0:
					tick = 0
			_spawns.append({
				"tick": tick,
				"enemy_id": row["enemy_id"],
				"order": order,
			})
			order += 1
	_spawns.sort_custom(_spawn_before)


func _spawn_before(a: Dictionary, b: Dictionary) -> bool:
	var tick_a := int(a["tick"])
	var tick_b := int(b["tick"])
	if tick_a == tick_b:
		return int(a["order"]) < int(b["order"])
	return tick_a < tick_b


func _spawn_due() -> void:
	var origin := Vector2.ZERO
	if not _map.waypoints.is_empty():
		origin = _map.waypoints[0]
	while _spawn_cursor < _spawns.size():
		var slot: Dictionary = _spawns[_spawn_cursor]
		if int(slot["tick"]) > _wave_tick:
			return
		_spawn_cursor += 1
		var enemy_id: StringName = slot["enemy_id"]
		var definition := _catalog.enemy(enemy_id)
		if definition == null:
			continue
		var enemy := EnemyState.new()
		enemy.id = _next_enemy_id
		_next_enemy_id += 1
		enemy.enemy_id = definition.id
		enemy.hp = _scaled_hp(definition.hp)
		enemy.speed = definition.speed
		enemy.position = origin
		_enemies.append(enemy)
		_events.append(GridwardEvents.enemy_spawned(enemy.id, enemy.enemy_id, origin))


func _scaled_hp(base_hp: int) -> int:
	var scaled := float(base_hp) * pow(_config.hp_scale, float(_wave_index)) * _config.difficulty_hp
	return maxi(roundi(scaled), 1)


func _move_enemies() -> void:
	var distance_scale := FixedTick.SEC
	var kept: Array[EnemyState] = []
	for enemy in _enemies:
		var leaked := enemy.advance(enemy.speed * distance_scale, _map.waypoints)
		if not leaked:
			kept.append(enemy)
			continue
		if _lives > 0:
			_lives -= 1
		_events.append(GridwardEvents.enemy_leaked(enemy.id, enemy.enemy_id, _lives))
		if _lives == 0 and _phase == Phase.WAVE:
			_phase = Phase.DEFEAT
			_events.append(GridwardEvents.defeat())
	_enemies = kept


## Tower targeting is intentionally empty until combat is added.
func _acquire_targets() -> void:
	pass


func _all_spawned() -> bool:
	return _spawn_cursor >= _spawns.size()


func _leave_wave_clear() -> void:
	if _wave_index + 1 >= _map.waves.size():
		_phase = Phase.VICTORY
		_events.append(GridwardEvents.victory())
		return
	_wave_index += 1
	_phase = Phase.BUILD
