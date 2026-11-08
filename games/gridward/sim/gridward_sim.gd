class_name GridwardSim
extends RefCounted

## Headless match. Towers place, target, and fire during BUILD and WAVE.

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
var _next_tower_id: int = 0
var _next_projectile_id: int = 0
var _enemies: Array[EnemyState] = []
var _towers: Array[TowerState] = []
var _projectiles: Array[ProjectileState] = []
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
	if _phase == Phase.WAVE:
		_resolve_combat()
	if _phase == Phase.WAVE and _all_spawned() and _enemies.is_empty():
		_phase = Phase.WAVE_CLEAR
		_projectiles.clear()
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


func get_towers() -> Array:
	var out: Array = []
	for tower in _towers:
		out.append(tower)
	return out


func get_projectiles() -> Array:
	var out: Array = []
	for shot in _projectiles:
		out.append(shot)
	return out


## Tower entity id, or -1 when the cell, unlock, gold, or phase rejects the build.
func place_tower(cell: Vector2i, tower_id: StringName) -> int:
	if not _commands_open() or not _map.is_buildable(cell):
		return -1
	if not _map.unlocked_towers.has(tower_id):
		return -1
	var definition := _catalog.tower(tower_id)
	if definition == null or _gold < definition.cost or _tower_at(cell) != null:
		return -1
	var tower := TowerState.new()
	tower.id = _next_tower_id
	_next_tower_id += 1
	tower.tower_id = definition.id
	tower.cell = cell
	tower.tier = 0
	tower.invested = definition.cost
	tower.base_cost = definition.cost
	tower.base_damage = definition.damage
	tower.base_range = definition.range
	tower.cooldown_ticks = definition.cooldown_ticks
	tower.cooldown = 0
	tower.kind = definition.kind
	tower.splash_radius = definition.splash_radius
	tower.anti_air = definition.anti_air
	tower.ground_only = definition.ground_only
	tower.targeting = TowerState.TARGET_FIRST
	_apply_tier_stats(tower)
	_gold -= definition.cost
	_towers.append(tower)
	_events.append(GridwardEvents.tower_placed(tower.id, tower.tower_id, cell, _gold))
	return tower.id


func sell_tower(tower_entity_id: int) -> bool:
	if not _commands_open():
		return false
	var index := _tower_index(tower_entity_id)
	if index < 0:
		return false
	var tower := _towers[index]
	var refund := _sell_refund(tower.invested)
	_gold += refund
	_towers.remove_at(index)
	_events.append(GridwardEvents.tower_sold(tower.id, refund, _gold))
	return true


func upgrade_tower(tower_entity_id: int) -> bool:
	if not _commands_open():
		return false
	var tower := _tower_by_id(tower_entity_id)
	if tower == null or tower.tier >= _config.max_tier:
		return false
	var cost := _upgrade_cost(tower.base_cost, tower.tier)
	if _gold < cost:
		return false
	_gold -= cost
	tower.invested += cost
	tower.tier += 1
	_apply_tier_stats(tower)
	_events.append(GridwardEvents.tower_upgraded(tower.id, tower.tier, cost, _gold))
	return true


func set_targeting(tower_entity_id: int, mode: StringName) -> void:
	var tower := _tower_by_id(tower_entity_id)
	if tower == null or not TowerState.is_targeting_mode(mode):
		return
	tower.targeting = mode


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


func _commands_open() -> bool:
	return _phase == Phase.BUILD or _phase == Phase.WAVE


func _sell_refund(invested: int) -> int:
	return floori(float(invested) * _config.sell_refund + 0.0000001)


func _upgrade_cost(base_cost: int, tier: int) -> int:
	var scaled := float(base_cost) * _config.upgrade_cost_factor * pow(_config.upgrade_cost_growth, float(tier))
	return roundi(scaled)


func _apply_tier_stats(tower: TowerState) -> void:
	var damage := float(tower.base_damage) * pow(_config.tier_damage_scale, float(tower.tier))
	tower.damage = maxi(roundi(damage), 1)
	tower.range = tower.base_range * pow(_config.tier_range_scale, float(tower.tier))


func _tower_at(cell: Vector2i) -> TowerState:
	for tower in _towers:
		if tower.cell == cell:
			return tower
	return null


func _tower_index(tower_entity_id: int) -> int:
	for i in _towers.size():
		if _towers[i].id == tower_entity_id:
			return i
	return -1


func _tower_by_id(tower_entity_id: int) -> TowerState:
	var index := _tower_index(tower_entity_id)
	if index < 0:
		return null
	return _towers[index]


func _enemy_by_id(enemy_id: int) -> EnemyState:
	for enemy in _enemies:
		if enemy.id == enemy_id:
			return enemy
	return null


func _resolve_combat() -> void:
	_advance_projectiles()
	_fire_towers()
	_remove_dead()


func _fire_towers() -> void:
	for tower in _towers:
		if tower.cooldown > 0:
			tower.cooldown -= 1
		if tower.cooldown > 0:
			continue
		if tower.kind == TowerDef.KIND_CONTINUOUS:
			continue
		var target := _acquire(tower)
		if target == null:
			continue
		tower.cooldown = tower.cooldown_ticks
		_events.append(GridwardEvents.tower_fired(tower.id, tower.tower_id, target.id, tower.kind))
		if tower.kind == TowerDef.KIND_PROJECTILE:
			_launch(tower, target)
		else:
			_damage_enemy(target, tower.damage, tower.id)


func _launch(tower: TowerState, target: EnemyState) -> void:
	var shot := ProjectileState.new()
	shot.id = _next_projectile_id
	_next_projectile_id += 1
	shot.tower_entity_id = tower.id
	shot.target_enemy_id = target.id
	shot.position = Vector2(tower.cell)
	shot.destination = target.position
	shot.damage = tower.damage
	shot.splash_radius = tower.splash_radius
	shot.anti_air = tower.anti_air
	shot.ground_only = tower.ground_only
	_projectiles.append(shot)
	_events.append(GridwardEvents.projectile_spawned(shot.id, tower.id, shot.position, target.id))


func _advance_projectiles() -> void:
	var step_distance := ProjectileState.SPEED * FixedTick.SEC
	var kept: Array[ProjectileState] = []
	var arrived: Array[ProjectileState] = []
	for shot in _projectiles:
		var target := _enemy_by_id(shot.target_enemy_id)
		if target != null and target.hp > 0:
			shot.destination = target.position
		var delta := shot.destination - shot.position
		var distance := delta.length()
		if distance <= step_distance or distance <= 0.0000001:
			shot.position = shot.destination
			arrived.append(shot)
		else:
			shot.position += delta * (step_distance / distance)
			kept.append(shot)
	_projectiles = kept
	for shot in arrived:
		_impact(shot)


func _impact(shot: ProjectileState) -> void:
	_events.append(GridwardEvents.projectile_impact(shot.id, shot.position, shot.splash_radius))
	for enemy in _enemies:
		if enemy.hp <= 0:
			continue
		if not _can_engage(shot.anti_air, shot.ground_only, enemy):
			continue
		if shot.splash_radius <= 0.0:
			if enemy.id != shot.target_enemy_id:
				continue
		elif shot.position.distance_to(enemy.position) > shot.splash_radius:
			continue
		_damage_enemy(enemy, shot.damage, shot.tower_entity_id)


func _acquire(tower: TowerState) -> EnemyState:
	var best: EnemyState = null
	var origin := Vector2(tower.cell)
	for enemy in _enemies:
		if enemy.hp <= 0:
			continue
		if origin.distance_to(enemy.position) > tower.range:
			continue
		if not _can_engage(tower.anti_air, tower.ground_only, enemy):
			continue
		if best == null or _prefer_target(tower.targeting, origin, enemy, best):
			best = enemy
	return best


func _prefer_target(mode: StringName, origin: Vector2, candidate: EnemyState, current: EnemyState) -> bool:
	match mode:
		TowerState.TARGET_LAST:
			return _lower_metric(_path_distance(candidate), _path_distance(current), candidate.id, current.id)
		TowerState.TARGET_CLOSEST:
			var candidate_distance := origin.distance_to(candidate.position)
			var current_distance := origin.distance_to(current.position)
			return _lower_metric(candidate_distance, current_distance, candidate.id, current.id)
		TowerState.TARGET_STRONGEST:
			return _higher_metric(float(candidate.hp), float(current.hp), candidate.id, current.id)
		TowerState.TARGET_WEAKEST:
			return _lower_metric(float(candidate.hp), float(current.hp), candidate.id, current.id)
		_:
			return _higher_metric(_path_distance(candidate), _path_distance(current), candidate.id, current.id)


func _higher_metric(candidate_metric: float, current_metric: float, candidate_id: int, current_id: int) -> bool:
	if not is_equal_approx(candidate_metric, current_metric):
		return candidate_metric > current_metric
	return candidate_id < current_id


func _lower_metric(candidate_metric: float, current_metric: float, candidate_id: int, current_id: int) -> bool:
	if not is_equal_approx(candidate_metric, current_metric):
		return candidate_metric < current_metric
	return candidate_id < current_id


func _path_distance(enemy: EnemyState) -> float:
	var total := 0.0
	var points := _map.waypoints
	var segments := mini(enemy.segment, maxi(points.size() - 1, 0))
	for i in segments:
		total += points[i].distance_to(points[i + 1])
	return total + enemy.segment_distance


func _can_engage(anti_air: bool, ground_only: bool, enemy: EnemyState) -> bool:
	var definition := _catalog.enemy(enemy.enemy_id)
	var is_air := definition != null and definition.is_air
	if is_air:
		return anti_air and not ground_only
	return true


func _damage_enemy(enemy: EnemyState, raw: int, tower_entity_id: int) -> void:
	var dealt := _apply_damage(enemy, raw)
	_events.append(GridwardEvents.enemy_hit(enemy.id, dealt, enemy.hp, tower_entity_id))
	if enemy.hp <= 0:
		_events.append(GridwardEvents.enemy_killed(enemy.id, enemy.enemy_id))


## Armor reduces the hit. Remaining damage is at least GridwardConfig.min_damage.
func _apply_damage(enemy: EnemyState, raw: int) -> int:
	var armor := 0
	var definition := _catalog.enemy(enemy.enemy_id)
	if definition != null:
		armor = definition.armor
	var dealt := raw - armor
	if dealt < _config.min_damage:
		dealt = _config.min_damage
	enemy.hp -= dealt
	if enemy.hp < 0:
		enemy.hp = 0
	return dealt


func _remove_dead() -> void:
	var kept: Array[EnemyState] = []
	for enemy in _enemies:
		if enemy.hp > 0:
			kept.append(enemy)
	_enemies = kept


func _all_spawned() -> bool:
	return _spawn_cursor >= _spawns.size()


func _leave_wave_clear() -> void:
	if _wave_index + 1 >= _map.waves.size():
		_phase = Phase.VICTORY
		_events.append(GridwardEvents.victory())
		return
	_wave_index += 1
	_phase = Phase.BUILD
