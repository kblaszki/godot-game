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
## Ticks left on the post-clear intermission. Zero during the opening build.
var _build_ticks_remaining: int = 0


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


## True in BUILD while the post-clear intermission still has ticks left.
func can_early_call() -> bool:
	if _phase != Phase.BUILD or _build_ticks_remaining <= 0 or _lives <= 0:
		return false
	return _wave_index >= 0 and _wave_index < _map.waves.size()


## Gold granted by start_wave during a pending intermission. Zero when can_early_call is false.
func early_call_bonus() -> int:
	if not can_early_call():
		return 0
	var per := _config.early_call_ticks_per_gold
	if per <= 0:
		return 0
	var raw := floori(float(_build_ticks_remaining) / float(per))
	if raw > _config.early_call_gold_cap:
		return _config.early_call_gold_cap
	return raw


func start_wave() -> bool:
	if _phase != Phase.BUILD:
		return false
	if _lives <= 0:
		_phase = Phase.DEFEAT
		_events.append(GridwardEvents.defeat())
		return false
	if _wave_index < 0 or _wave_index >= _map.waves.size():
		return false
	var bonus := early_call_bonus()
	_gold += bonus
	_build_ticks_remaining = 0
	_build_schedule(_map.waves[_wave_index])
	_wave_tick = 0
	_phase = Phase.WAVE
	_events.append(GridwardEvents.wave_started(_wave_index, bonus))
	return true


func step() -> void:
	if _phase == Phase.WAVE_CLEAR:
		_leave_wave_clear()
		return
	if _phase == Phase.BUILD:
		if _build_ticks_remaining > 0:
			_build_ticks_remaining -= 1
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
		var bonus := _wave_clear_bonus()
		_gold += bonus
		_events.append(GridwardEvents.wave_cleared(_wave_index, bonus, _gold))
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
	tower.slow_factor = definition.slow_factor
	tower.slow_ticks = definition.slow_ticks
	tower.base_ramp = definition.ramp_damage
	tower.burn_stacks = definition.burn_stacks
	tower.burn_ticks = definition.burn_ticks
	tower.focus_id = -1
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
		enemy.armor = definition.armor
		enemy.is_air = definition.is_air
		enemy.position = origin
		_enemies.append(enemy)
		_events.append(GridwardEvents.enemy_spawned(enemy.id, enemy.enemy_id, origin))


func _scaled_hp(base_hp: int) -> int:
	return scaled_enemy_hp(base_hp, _wave_index, _config.hp_scale, _config.difficulty_hp)


func _wave_clear_bonus() -> int:
	return _config.wave_clear_bonus_base + _config.wave_clear_bonus_per_index * _wave_index


func _kill_bounty(enemy: EnemyState) -> int:
	var definition := _catalog.enemy(enemy.enemy_id)
	if definition == null:
		return 0
	return definition.bounty


func _move_enemies() -> void:
	var distance_scale := FixedTick.SEC
	var kept: Array[EnemyState] = []
	for enemy in _enemies:
		var pace := enemy.speed * (1.0 - _current_slow(enemy))
		var leaked := enemy.advance(pace * distance_scale, _map.waypoints)
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
	return upgrade_cost(base_cost, tier, _config.upgrade_cost_factor, _config.upgrade_cost_growth)


## round(base_cost * factor * pow(growth, tier)) for the step from tier t to t+1.
static func upgrade_cost(base_cost: int, tier: int, factor: float, growth: float) -> int:
	var scaled := float(base_cost) * factor * pow(growth, float(tier))
	return roundi(scaled)


## Spawn HP: max(1, round(base * pow(hp_scale, wave_index) * difficulty_hp)).
static func scaled_enemy_hp(base_hp: int, wave_index: int, hp_scale: float, difficulty_hp: float) -> int:
	var scaled := float(base_hp) * pow(hp_scale, float(wave_index)) * difficulty_hp
	return maxi(roundi(scaled), 1)


## Hitscan and projectile damage per second. Period is cooldown_ticks steps.
static func tower_dps(damage: int, cooldown_ticks: int) -> float:
	if cooldown_ticks <= 0:
		return 0.0
	return float(damage) / (float(cooldown_ticks) * FixedTick.SEC)


## Spec lane-hold estimate: dps * (coverage_length / enemy_speed).
static func estimated_lane_damage(dps: float, coverage_length: float, enemy_speed: float) -> float:
	if enemy_speed <= 0.0:
		return 0.0
	return dps * (coverage_length / enemy_speed)


## Length of the waypoint polyline that lies within attack_range of origin.
static func path_coverage_length(waypoints: PackedVector2Array, origin: Vector2, attack_range: float) -> float:
	if waypoints.size() < 2 or attack_range <= 0.0:
		return 0.0
	var total := 0.0
	var radius_sq := attack_range * attack_range
	for i in range(waypoints.size() - 1):
		var start: Vector2 = waypoints[i]
		var finish: Vector2 = waypoints[i + 1]
		var delta := finish - start
		var length := delta.length()
		if length <= 0.0000001:
			continue
		var offset := start - origin
		var a := delta.dot(delta)
		var b := 2.0 * offset.dot(delta)
		var c := offset.dot(offset) - radius_sq
		var disc := b * b - 4.0 * a * c
		if disc < 0.0:
			continue
		var root := sqrt(disc)
		var inv := 1.0 / (2.0 * a)
		var t_enter := (-b - root) * inv
		var t_leave := (-b + root) * inv
		var enter := clampf(t_enter, 0.0, 1.0)
		var leave := clampf(t_leave, 0.0, 1.0)
		if leave > enter:
			total += (leave - enter) * length
	return total


func _apply_tier_stats(tower: TowerState) -> void:
	var damage := float(tower.base_damage) * pow(_config.tier_damage_scale, float(tower.tier))
	tower.damage = maxi(roundi(damage), 1)
	tower.range = tower.base_range * pow(_config.tier_range_scale, float(tower.tier))
	if tower.base_ramp <= 0:
		tower.ramp_damage = 0
		return
	var ramp := float(tower.base_ramp) * pow(_config.tier_damage_scale, float(tower.tier))
	tower.ramp_damage = maxi(roundi(ramp), tower.damage)
	if tower.beam_damage < tower.damage:
		tower.beam_damage = tower.damage
	elif tower.beam_damage > tower.ramp_damage:
		tower.beam_damage = tower.ramp_damage


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
	_tick_statuses()
	_advance_projectiles()
	_fire_towers()
	_remove_dead()


func _fire_towers() -> void:
	for tower in _towers:
		if tower.cooldown > 0:
			tower.cooldown -= 1
		if tower.cooldown > 0:
			continue
		var target := _acquire(tower)
		if target == null:
			continue
		if tower.kind == TowerDef.KIND_CONTINUOUS:
			_fire_beam(tower, target)
			continue
		tower.cooldown = tower.cooldown_ticks
		_events.append(GridwardEvents.tower_fired(tower.id, tower.tower_id, target.id, tower.kind))
		if tower.kind == TowerDef.KIND_PROJECTILE:
			_launch(tower, target)
		else:
			_damage_enemy(target, tower.damage, tower.id)
			_apply_on_hit_statuses(tower, target)


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
	if enemy.is_air:
		return anti_air and not ground_only
	return true


func _fire_beam(tower: TowerState, target: EnemyState) -> void:
	if target.id != tower.focus_id:
		tower.focus_id = target.id
		tower.beam_damage = tower.damage
	var raw := tower.beam_damage
	tower.cooldown = tower.cooldown_ticks
	_events.append(GridwardEvents.tower_fired(tower.id, tower.tower_id, target.id, tower.kind))
	_damage_enemy(target, raw, tower.id)
	_apply_on_hit_statuses(tower, target)
	if tower.beam_damage < tower.ramp_damage:
		tower.beam_damage += 1


func _apply_on_hit_statuses(tower: TowerState, enemy: EnemyState) -> void:
	if enemy.hp <= 0:
		return
	_apply_slow(enemy, tower.slow_factor, tower.slow_ticks, tower.id)
	_apply_burn(enemy, tower.burn_stacks, tower.burn_ticks, tower.id)


func _damage_enemy(enemy: EnemyState, raw: int, tower_entity_id: int) -> void:
	if enemy.hp <= 0:
		return
	var dealt := _apply_damage(enemy, raw)
	_finish_hit(enemy, dealt, tower_entity_id)


func _finish_hit(enemy: EnemyState, dealt: int, tower_entity_id: int) -> void:
	_events.append(GridwardEvents.enemy_hit(enemy.id, dealt, enemy.hp, tower_entity_id))
	if enemy.hp > 0:
		return
	var bounty := _kill_bounty(enemy)
	_gold += bounty
	_events.append(GridwardEvents.enemy_killed(enemy.id, enemy.enemy_id, bounty, _gold))


## Armor reduces the hit. Remaining damage is at least GridwardConfig.min_damage.
func _apply_damage(enemy: EnemyState, raw: int) -> int:
	var dealt := raw - enemy.armor
	if dealt < _config.min_damage:
		dealt = _config.min_damage
	enemy.hp -= dealt
	if enemy.hp < 0:
		enemy.hp = 0
	return dealt


## Burn damage and duration decay. Runs after movement and before shots, so a
## newly applied status lasts its full tick count on later steps.
func _tick_statuses() -> void:
	for enemy in _enemies:
		if enemy.hp <= 0:
			continue
		var burn := _find_status(enemy, StatusEffect.BURN)
		if burn != null and burn.remaining_ticks > 0:
			var raw := int(burn.magnitude) * _config.burn_damage_per_stack
			_damage_burn(enemy, raw, burn.source_id)
		var kept: Array[StatusEffect] = []
		for effect in enemy.statuses:
			effect.remaining_ticks -= 1
			if effect.remaining_ticks > 0:
				kept.append(effect)
		enemy.statuses = kept


func _damage_burn(enemy: EnemyState, raw: int, source_id: int) -> void:
	if raw <= 0 or enemy.hp <= 0:
		return
	enemy.hp -= raw
	if enemy.hp < 0:
		enemy.hp = 0
	_finish_hit(enemy, raw, source_id)


func _apply_slow(enemy: EnemyState, factor: float, ticks: int, source_id: int) -> void:
	if factor <= 0.0 or ticks <= 0:
		return
	var capped := factor
	if capped > _config.slow_cap:
		capped = _config.slow_cap
	if capped <= 0.0:
		return
	var existing := _find_status(enemy, StatusEffect.SLOW)
	if existing != null and capped < existing.magnitude:
		return
	if existing == null:
		existing = StatusEffect.new()
		existing.kind = StatusEffect.SLOW
		enemy.statuses.append(existing)
	existing.magnitude = capped
	existing.remaining_ticks = ticks
	existing.source_id = source_id


func _apply_burn(enemy: EnemyState, stacks: int, ticks: int, source_id: int) -> void:
	if stacks <= 0 or ticks <= 0:
		return
	var existing := _find_status(enemy, StatusEffect.BURN)
	if existing == null:
		existing = StatusEffect.new()
		existing.kind = StatusEffect.BURN
		existing.magnitude = float(mini(stacks, _config.burn_max_stacks))
		existing.remaining_ticks = ticks
		existing.source_id = source_id
		enemy.statuses.append(existing)
		return
	var combined := int(existing.magnitude) + stacks
	if combined > _config.burn_max_stacks:
		combined = _config.burn_max_stacks
	existing.magnitude = float(combined)
	existing.remaining_ticks = ticks
	existing.source_id = source_id


func _current_slow(enemy: EnemyState) -> float:
	var effect := _find_status(enemy, StatusEffect.SLOW)
	if effect == null:
		return 0.0
	if effect.magnitude < 0.0:
		return 0.0
	if effect.magnitude > 1.0:
		return 1.0
	return effect.magnitude


func _find_status(enemy: EnemyState, kind: StringName) -> StatusEffect:
	for effect in enemy.statuses:
		if effect.kind == kind:
			return effect
	return null


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
	_build_ticks_remaining = _config.build_timer_ticks
