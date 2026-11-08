class_name GridwardCatalog
extends RefCounted

## Pure builders for Gridward content. Callers inject the returned defs into the sim.
## enemy() and tower() each return a new instance. Unknown ids return null.

const MEADOW: StringName = &"meadow"

const ENEMY_IDS: Array[StringName] = [
	&"grunt",
	&"runner",
	&"tank",
	&"swarm",
	&"flyer",
	&"boss",
]

const TOWER_IDS: Array[StringName] = [
	&"bolt",
	&"mortar",
	&"frost",
	&"flak",
	&"beam",
]

static func build_meadow() -> MapDef:
	var map := MapDef.new()
	map.id = MEADOW
	map.width = 16
	map.height = 10
	map.starting_gold = 120
	map.starting_lives = 20
	# S-curve in cell indices: east along the north lane, south, west, south, east to the exit.
	map.waypoints = PackedVector2Array([
		Vector2(0, 1),
		Vector2(12, 1),
		Vector2(12, 4),
		Vector2(3, 4),
		Vector2(3, 7),
		Vector2(15, 7),
	])
	map.unlocked_towers = [&"bolt"]
	map.waves = _meadow_waves()
	map.apply_buildable_off_path()
	return map

static func enemy(id: StringName) -> EnemyDef:
	match id:
		&"grunt":
			return _enemy(&"grunt", 40, 1.2, 8, 0, false, false, false)
		&"runner":
			return _enemy(&"runner", 24, 2.4, 10, 0, false, false, false)
		&"tank":
			return _enemy(&"tank", 120, 0.7, 18, 4, false, false, false)
		&"swarm":
			return _enemy(&"swarm", 12, 1.8, 3, 0, false, true, false)
		&"flyer":
			return _enemy(&"flyer", 36, 1.6, 14, 0, true, false, false)
		&"boss":
			return _enemy(&"boss", 800, 0.55, 100, 6, false, false, true)
		_:
			return null

static func tower(id: StringName) -> TowerDef:
	match id:
		&"bolt":
			return _tower(&"bolt", 50, 2.5, 30, 12, TowerDef.KIND_HITSCAN, 0.0, 0.0, 0, false, true, 0)
		&"mortar":
			return _tower(&"mortar", 80, 3.5, 75, 28, TowerDef.KIND_PROJECTILE, 1.2, 0.0, 0, false, true, 0)
		&"frost":
			return _tower(&"frost", 70, 2.2, 45, 4, TowerDef.KIND_HITSCAN, 0.0, 0.35, 90, false, true, 0)
		&"flak":
			return _tower(&"flak", 90, 3.0, 24, 10, TowerDef.KIND_HITSCAN, 0.0, 0.0, 0, true, false, 0)
		&"beam":
			return _tower(&"beam", 110, 2.8, 6, 3, TowerDef.KIND_CONTINUOUS, 0.0, 0.0, 0, false, true, 12)
		_:
			return null

static func _meadow_waves() -> Array[WaveDef]:
	var waves: Array[WaveDef] = []
	# Teach grunt, test the count, teach runner, then mix.
	waves.append(_wave_of([[&"grunt", 4, 70, 0]]))
	waves.append(_wave_of([[&"grunt", 6, 60, 0]]))
	waves.append(_wave_of([[&"runner", 4, 50, 0]]))
	waves.append(_wave_of([
		[&"grunt", 5, 60, 0],
		[&"runner", 3, 45, 360],
	]))
	# Wider spacing, small pack: a short rest before the runner test.
	waves.append(_wave_of([[&"grunt", 5, 80, 0]]))
	waves.append(_wave_of([[&"runner", 6, 40, 0]]))
	waves.append(_wave_of([
		[&"grunt", 6, 50, 0],
		[&"runner", 5, 36, 320],
	]))
	waves.append(_wave_of([[&"grunt", 10, 45, 0]]))
	waves.append(_wave_of([[&"runner", 8, 35, 0]]))
	waves.append(_wave_of([
		[&"grunt", 8, 40, 0],
		[&"runner", 8, 30, 360],
	]))
	return waves

static func _wave_of(rows: Array) -> WaveDef:
	var wave := WaveDef.new()
	for row in rows:
		wave.entries.append({
			"enemy_id": row[0],
			"count": row[1],
			"spacing_ticks": row[2],
			"delay_ticks": row[3],
		})
	return wave

static func _enemy(
	id: StringName,
	hp: int,
	speed: float,
	bounty: int,
	armor: int,
	is_air: bool,
	is_group: bool,
	is_boss: bool
) -> EnemyDef:
	var enemy := EnemyDef.new()
	enemy.id = id
	enemy.hp = hp
	enemy.speed = speed
	enemy.bounty = bounty
	enemy.armor = armor
	enemy.is_air = is_air
	enemy.is_group = is_group
	enemy.is_boss = is_boss
	return enemy

static func _tower(
	id: StringName,
	cost: int,
	tower_range: float,
	cooldown_ticks: int,
	damage: int,
	kind: StringName,
	splash_radius: float,
	slow_factor: float,
	slow_ticks: int,
	anti_air: bool,
	ground_only: bool,
	ramp_damage: int
) -> TowerDef:
	var built := TowerDef.new()
	built.id = id
	built.cost = cost
	built.range = tower_range
	built.cooldown_ticks = cooldown_ticks
	built.damage = damage
	built.kind = kind
	built.splash_radius = splash_radius
	built.slow_factor = slow_factor
	built.slow_ticks = slow_ticks
	built.anti_air = anti_air
	built.ground_only = ground_only
	built.ramp_damage = ramp_damage
	return built
