class_name GridwardCatalog
extends RefCounted

## Pure builders for Gridward content. Callers inject the returned defs into the sim.
## enemy() and tower() each return a new instance. Unknown ids return null.

const MEADOW: StringName = &"meadow"
const BEND: StringName = &"bend"
const SKYREACH: StringName = &"skyreach"
const BASTION: StringName = &"bastion"
const CITADEL: StringName = &"citadel"

const MAP_IDS: Array[StringName] = [
	MEADOW,
	BEND,
	SKYREACH,
	BASTION,
	CITADEL,
]

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


static func build_bend() -> MapDef:
	var map := MapDef.new()
	map.id = BEND
	map.width = 16
	map.height = 10
	map.starting_gold = 150
	map.starting_lives = 20
	# Corner bends so a mortar on the inside covers a packed lane.
	map.waypoints = PackedVector2Array([
		Vector2(0, 2),
		Vector2(11, 2),
		Vector2(11, 6),
		Vector2(3, 6),
		Vector2(3, 8),
		Vector2(15, 8),
	])
	map.unlocked_towers = [&"bolt", &"mortar"]
	map.waves = _bend_waves()
	map.apply_buildable_off_path()
	return map


static func build_skyreach() -> MapDef:
	var map := MapDef.new()
	map.id = SKYREACH
	map.width = 16
	map.height = 10
	map.starting_gold = 180
	map.starting_lives = 20
	map.waypoints = PackedVector2Array([
		Vector2(0, 1),
		Vector2(15, 1),
		Vector2(15, 5),
		Vector2(0, 5),
		Vector2(0, 8),
		Vector2(15, 8),
	])
	map.unlocked_towers = [&"bolt", &"mortar", &"flak"]
	map.waves = _skyreach_waves()
	map.apply_buildable_off_path()
	return map


static func build_bastion() -> MapDef:
	var map := MapDef.new()
	map.id = BASTION
	map.width = 16
	map.height = 10
	map.starting_gold = 200
	map.starting_lives = 20
	map.waypoints = PackedVector2Array([
		Vector2(0, 4),
		Vector2(6, 4),
		Vector2(6, 1),
		Vector2(12, 1),
		Vector2(12, 8),
		Vector2(4, 8),
		Vector2(4, 6),
		Vector2(15, 6),
	])
	map.unlocked_towers = [&"bolt", &"mortar", &"frost", &"flak"]
	map.waves = _bastion_waves()
	map.apply_buildable_off_path()
	return map


static func build_citadel() -> MapDef:
	var map := MapDef.new()
	map.id = CITADEL
	map.width = 16
	map.height = 10
	map.starting_gold = 240
	map.starting_lives = 20
	map.waypoints = PackedVector2Array([
		Vector2(0, 1),
		Vector2(14, 1),
		Vector2(14, 3),
		Vector2(2, 3),
		Vector2(2, 5),
		Vector2(14, 5),
		Vector2(14, 8),
		Vector2(15, 8),
	])
	map.unlocked_towers = [&"bolt", &"mortar", &"frost", &"flak", &"beam"]
	map.waves = _citadel_waves()
	map.apply_buildable_off_path()
	return map


static func build_map(map_id: StringName) -> MapDef:
	match map_id:
		MEADOW:
			return build_meadow()
		BEND:
			return build_bend()
		SKYREACH:
			return build_skyreach()
		BASTION:
			return build_bastion()
		CITADEL:
			return build_citadel()
		_:
			return null


static func map_title(map_id: StringName) -> String:
	match map_id:
		MEADOW:
			return "Meadow"
		BEND:
			return "Bend"
		SKYREACH:
			return "Skyreach"
		BASTION:
			return "Bastion"
		CITADEL:
			return "Citadel"
		_:
			return str(map_id).capitalize()


## Lives remaining for 3 stars, then 2 stars. Every map uses the spec §9 gates.
static func star_thresholds(_map_id: StringName) -> Vector2i:
	return Vector2i(15, 8)


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

static func _bend_waves() -> Array[WaveDef]:
	var waves: Array[WaveDef] = []
	# Teach the grunt line, then a tight pack the mortar can splash.
	waves.append(_wave_of([[&"grunt", 4, 70, 0]]))
	waves.append(_wave_of([[&"grunt", 6, 55, 0]]))
	waves.append(_wave_of([[&"grunt", 8, 20, 0]]))
	waves.append(_wave_of([
		[&"grunt", 5, 50, 0],
		[&"runner", 3, 40, 300],
	]))
	waves.append(_wave_of([[&"swarm", 8, 16, 0]]))
	# Wider spacing: a short rest before the packed test.
	waves.append(_wave_of([[&"grunt", 6, 70, 0]]))
	waves.append(_wave_of([
		[&"grunt", 6, 24, 0],
		[&"swarm", 6, 14, 200],
	]))
	waves.append(_wave_of([[&"runner", 6, 36, 0]]))
	waves.append(_wave_of([
		[&"swarm", 10, 14, 0],
		[&"grunt", 4, 40, 180],
	]))
	waves.append(_wave_of([
		[&"grunt", 8, 30, 0],
		[&"runner", 4, 32, 280],
	]))
	waves.append(_wave_of([
		[&"swarm", 8, 12, 0],
		[&"grunt", 6, 28, 160],
	]))
	waves.append(_wave_of([
		[&"grunt", 8, 26, 0],
		[&"runner", 6, 30, 240],
		[&"swarm", 6, 16, 480],
	]))
	return waves


static func _skyreach_waves() -> Array[WaveDef]:
	var waves: Array[WaveDef] = []
	waves.append(_wave_of([[&"grunt", 4, 70, 0]]))
	waves.append(_wave_of([[&"grunt", 5, 55, 0]]))
	# Teach flyers. Ground towers cannot hit them.
	waves.append(_wave_of([[&"flyer", 4, 50, 0]]))
	waves.append(_wave_of([
		[&"flyer", 3, 45, 0],
		[&"grunt", 4, 50, 220],
	]))
	waves.append(_wave_of([[&"grunt", 5, 70, 0]]))
	waves.append(_wave_of([[&"flyer", 6, 40, 0]]))
	waves.append(_wave_of([
		[&"runner", 4, 40, 0],
		[&"flyer", 4, 36, 200],
	]))
	waves.append(_wave_of([
		[&"flyer", 5, 34, 0],
		[&"swarm", 6, 18, 180],
	]))
	waves.append(_wave_of([
		[&"grunt", 6, 40, 0],
		[&"flyer", 5, 32, 240],
	]))
	waves.append(_wave_of([[&"flyer", 8, 30, 0]]))
	waves.append(_wave_of([
		[&"runner", 5, 34, 0],
		[&"flyer", 6, 28, 200],
	]))
	waves.append(_wave_of([
		[&"grunt", 6, 36, 0],
		[&"flyer", 6, 26, 220],
		[&"swarm", 4, 16, 400],
	]))
	return waves


static func _bastion_waves() -> Array[WaveDef]:
	var waves: Array[WaveDef] = []
	waves.append(_wave_of([[&"grunt", 4, 70, 0]]))
	waves.append(_wave_of([[&"runner", 4, 45, 0]]))
	waves.append(_wave_of([
		[&"grunt", 5, 50, 0],
		[&"runner", 3, 40, 280],
	]))
	# Teach armor. Frost slows the tank so bolts have more time on target.
	waves.append(_wave_of([[&"tank", 2, 80, 0]]))
	waves.append(_wave_of([
		[&"tank", 2, 70, 0],
		[&"grunt", 4, 50, 200],
	]))
	waves.append(_wave_of([[&"grunt", 5, 75, 0]]))
	waves.append(_wave_of([[&"tank", 3, 60, 0]]))
	waves.append(_wave_of([
		[&"tank", 2, 70, 0],
		[&"runner", 4, 36, 240],
	]))
	waves.append(_wave_of([
		[&"flyer", 4, 40, 0],
		[&"grunt", 4, 45, 180],
	]))
	waves.append(_wave_of([
		[&"tank", 3, 55, 0],
		[&"swarm", 6, 16, 200],
	]))
	waves.append(_wave_of([[&"tank", 4, 50, 0]]))
	waves.append(_wave_of([
		[&"flyer", 4, 34, 0],
		[&"tank", 2, 70, 220],
	]))
	waves.append(_wave_of([
		[&"tank", 3, 48, 0],
		[&"runner", 5, 32, 200],
	]))
	waves.append(_wave_of([
		[&"grunt", 6, 36, 0],
		[&"tank", 3, 50, 240],
		[&"flyer", 3, 30, 420],
	]))
	return waves


static func _citadel_waves() -> Array[WaveDef]:
	var waves: Array[WaveDef] = []
	waves.append(_wave_of([[&"grunt", 5, 60, 0]]))
	waves.append(_wave_of([[&"runner", 4, 40, 0]]))
	waves.append(_wave_of([[&"swarm", 8, 16, 0]]))
	waves.append(_wave_of([[&"flyer", 4, 40, 0]]))
	waves.append(_wave_of([[&"tank", 2, 70, 0]]))
	waves.append(_wave_of([[&"grunt", 4, 70, 0]]))
	waves.append(_wave_of([
		[&"tank", 2, 60, 0],
		[&"flyer", 3, 36, 200],
	]))
	waves.append(_wave_of([
		[&"swarm", 8, 14, 0],
		[&"grunt", 5, 40, 160],
	]))
	waves.append(_wave_of([
		[&"runner", 5, 32, 0],
		[&"tank", 2, 65, 220],
	]))
	waves.append(_wave_of([
		[&"flyer", 5, 30, 0],
		[&"swarm", 6, 16, 180],
	]))
	waves.append(_wave_of([
		[&"tank", 3, 50, 0],
		[&"grunt", 4, 40, 200],
	]))
	waves.append(_wave_of([
		[&"flyer", 4, 28, 0],
		[&"tank", 2, 60, 200],
		[&"runner", 4, 30, 360],
	]))
	# Teach the boss alone enough to ramp a beam, then a mixed climax.
	waves.append(_wave_of([
		[&"boss", 1, 10, 0],
		[&"grunt", 4, 40, 120],
	]))
	waves.append(_wave_of([
		[&"tank", 2, 55, 0],
		[&"flyer", 4, 30, 180],
		[&"swarm", 6, 14, 300],
	]))
	waves.append(_wave_of([
		[&"boss", 1, 10, 0],
		[&"tank", 1, 80, 80],
		[&"flyer", 3, 32, 200],
		[&"grunt", 4, 36, 320],
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
