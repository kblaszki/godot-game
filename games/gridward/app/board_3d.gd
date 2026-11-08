class_name GridwardBoard3D
extends Node3D

## Meadow-style grid on the XZ plane. One world unit is one cell.
## `cell_to_world` returns the cell center. Meshes are skipped headless.

const CELL := 1.0
const PITCH_DEG := 40.0
const CAM_YAW := PI * 0.25
const ORBIT_SENS := 0.008
const SKY := Color(0.53, 0.74, 0.92, 1)
## Vector2i cannot store INF. This is the miss sentinel for cell_at_screen.
const MISS_CELL := Vector2i(2147483647, 2147483647)

const GRASS := Color(0.34, 0.6, 0.34, 1)
const PATH := Color(0.76, 0.64, 0.36, 1)
const PATH_BAR := Color(0.55, 0.4, 0.22, 1)
const GROUND := Color(0.2, 0.38, 0.24, 1)
const BLOCKED := Color(0.32, 0.34, 0.36, 1)
const GHOST_OK := Color(0.3, 0.85, 0.4, 0.5)
const GHOST_BAD := Color(0.9, 0.22, 0.2, 0.5)

var _camera: Camera3D
var _pivot: Node3D
var _cells_root: Node3D
var _path_root: Node3D
var _towers_root: Node3D
var _enemies_root: Node3D
var _ghost: MeshInstance3D
var _tower_nodes: Dictionary = {}
var _enemy_nodes: Dictionary = {}
var _focus: Vector3 = Vector3.ZERO
var _board_center: Vector3 = Vector3.ZERO
var _distance: float = 18.0
var _dist_min: float = 4.0
var _dist_max: float = 80.0
var _bounds_radius: float = 8.0
var _yaw: float = 0.0
var _orbiting: bool = false
var _panning: bool = false
var _built: bool = false
var _map_key: String = ""
var _ghost_cell: Vector2i = MISS_CELL
var _ghost_ok: bool = false


func _ready() -> void:
	_ensure_rig()


func _process(_delta: float) -> void:
	_apply_camera()


func get_camera() -> Camera3D:
	return _camera


func is_orbiting() -> bool:
	return _orbiting


func is_panning() -> bool:
	return _panning


static func is_miss(cell: Vector2i) -> bool:
	return cell == MISS_CELL


## Local +X follows an XZ delta. Vector2.y is world Z. Same convention as Course3D.
static func yaw_for_xz_delta(delta: Vector2) -> float:
	return atan2(-delta.y, delta.x)


## Center of the cell on the Y=0 plane.
static func cell_to_world(cell: Vector2i) -> Vector3:
	return point_to_world(Vector2(cell))


## Continuous cell-space point (waypoints and enemies) to the XZ plane.
static func point_to_world(point: Vector2) -> Vector3:
	return Vector3((point.x + 0.5) * CELL, 0.0, (point.y + 0.5) * CELL)


static func world_to_cell(world: Vector3) -> Vector2i:
	return Vector2i(floori(world.x / CELL), floori(world.z / CELL))


func sync_from_sim(sim: GridwardSim) -> void:
	if sim == null:
		return
	_ensure_rig()
	var map: MapDef = sim._map
	if map == null:
		return
	var key := _map_key_for(map)
	if key != _map_key:
		_map_key = key
		_rebuild_static(map)
		_focus = _board_center
		_distance = clampf(_bounds_radius * 2.15, _dist_min, _dist_max)
		_apply_camera()
	_sync_towers(sim.get_towers())
	_sync_enemies(sim.get_enemies())


## Viewport pixels. Returns MISS_CELL when the ray misses the ground plane.
func cell_at_screen(pos: Vector2) -> Vector2i:
	if _camera == null or not is_instance_valid(_camera) or not _camera.is_inside_tree():
		return MISS_CELL
	if not is_finite(pos.x) or not is_finite(pos.y):
		return MISS_CELL
	var origin := _camera.project_ray_origin(pos)
	var direction := _camera.project_ray_normal(pos)
	if absf(direction.y) < 0.0001:
		return MISS_CELL
	var t := -origin.y / direction.y
	if t < 0.0:
		return MISS_CELL
	return world_to_cell(origin + direction * t)


## Green when `ok`, red otherwise. MISS_CELL hides the ghost.
func set_ghost(cell: Vector2i, ok: bool) -> void:
	_ghost_cell = cell
	_ghost_ok = ok
	_place_ghost()


func begin_orbit() -> void:
	_orbiting = true
	_panning = false


func end_orbit() -> void:
	_orbiting = false


func begin_pan() -> void:
	_panning = true
	_orbiting = false


func end_pan() -> void:
	_panning = false


func orbit(delta_x: float) -> void:
	_yaw += delta_x * ORBIT_SENS
	_apply_camera()


func pan(delta: Vector2) -> void:
	var yaw := _yaw + CAM_YAW
	var right := Vector3(1, 0, 0).rotated(Vector3.UP, yaw)
	var forward := Vector3(0, 0, -1).rotated(Vector3.UP, yaw)
	_focus += (right * -delta.x + forward * -delta.y) * (_distance * 0.0015)
	_focus.y = 0.0
	_apply_camera()


func dolly(factor: float) -> void:
	if absf(factor) < 0.0001:
		return
	_distance = clampf(_distance / factor, _dist_min, _dist_max)
	_apply_camera()


func fit(view_size: Vector2) -> void:
	_ensure_rig()
	_orbiting = false
	_panning = false
	_yaw = 0.0
	_focus = _board_center
	_distance = _fit_distance(view_size)
	_apply_camera()


func _ensure_rig() -> void:
	if _built:
		return
	_built = true
	_apply_bounds(16, 10)
	_focus = _board_center

	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.84, 0.88, 0.92, 1)
	env.ambient_light_energy = 0.85
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_energy = 1.15
	sun.light_color = Color(1.0, 0.97, 0.92, 1)
	sun.shadow_enabled = _use_meshes()
	add_child(sun)

	_pivot = Node3D.new()
	_pivot.name = "BoardPivot3D"
	add_child(_pivot)

	_cells_root = Node3D.new()
	_cells_root.name = "Cells"
	_pivot.add_child(_cells_root)
	_path_root = Node3D.new()
	_path_root.name = "Path"
	_pivot.add_child(_path_root)
	_towers_root = Node3D.new()
	_towers_root.name = "Towers"
	_pivot.add_child(_towers_root)
	_enemies_root = Node3D.new()
	_enemies_root.name = "Enemies"
	_pivot.add_child(_enemies_root)

	if _use_meshes():
		_ghost = MeshInstance3D.new()
		_ghost.name = "Ghost"
		var box := BoxMesh.new()
		box.size = Vector3(0.9, 0.7, 0.9)
		_ghost.mesh = box
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = GHOST_OK
		_ghost.material_override = mat
		_ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_ghost.visible = false
		_pivot.add_child(_ghost)

	_camera = Camera3D.new()
	_camera.name = "Camera3D"
	_camera.fov = 42.0
	_camera.near = 0.05
	_camera.far = 400.0
	_camera.current = true
	add_child(_camera)
	_apply_camera()


func _use_meshes() -> bool:
	return not OS.has_feature("headless") and DisplayServer.get_name() != "headless"


func _map_key_for(map: MapDef) -> String:
	var tail := Vector2.ZERO
	if not map.waypoints.is_empty():
		tail = map.waypoints[map.waypoints.size() - 1]
	return "%s:%d:%d:%d:%.0f:%.0f" % [
		map.id, map.width, map.height, map.waypoints.size(), tail.x, tail.y
	]


func _rebuild_static(map: MapDef) -> void:
	_clear(_cells_root)
	_clear(_path_root)
	_apply_bounds(map.width, map.height)
	if not _use_meshes():
		return
	_add_ground(map.width, map.height)
	var on_path := {}
	for cell in map.path_cells():
		on_path[cell] = true
	var tile := BoxMesh.new()
	tile.size = Vector3(0.92 * CELL, 0.06, 0.92 * CELL)
	var grass_mat := _mat(GRASS)
	var path_mat := _mat(PATH)
	var blocked_mat := _mat(BLOCKED)
	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y)
			var node := MeshInstance3D.new()
			node.mesh = tile
			if on_path.has(cell):
				node.material_override = path_mat
			elif map.is_buildable(cell):
				node.material_override = grass_mat
			else:
				node.material_override = blocked_mat
			node.position = cell_to_world(cell) + Vector3(0.0, 0.035, 0.0)
			_cells_root.add_child(node)
	_add_path_bars(map)


func _add_ground(width: int, height: int) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = "Ground"
	var box := BoxMesh.new()
	box.size = Vector3(float(width) * CELL, 0.12, float(height) * CELL)
	mesh.mesh = box
	mesh.material_override = _mat(GROUND)
	mesh.position = Vector3(float(width) * CELL * 0.5, -0.06, float(height) * CELL * 0.5)
	_cells_root.add_child(mesh)


func _add_path_bars(map: MapDef) -> void:
	var points := map.waypoints
	if points.size() < 2:
		return
	for i in range(1, points.size()):
		var a := point_to_world(points[i - 1])
		var b := point_to_world(points[i])
		var delta := Vector2(b.x - a.x, b.z - a.z)
		if delta.length_squared() < 0.0001:
			continue
		var bar := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(delta.length(), 0.04, 0.22)
		bar.mesh = box
		bar.material_override = _mat(PATH_BAR)
		bar.position = (a + b) * 0.5 + Vector3(0.0, 0.09, 0.0)
		bar.rotation = Vector3(0.0, yaw_for_xz_delta(delta), 0.0)
		_path_root.add_child(bar)


func _sync_towers(towers: Array) -> void:
	if not _use_meshes():
		return
	var live := {}
	for item in towers:
		var tower := item as TowerState
		if tower == null:
			continue
		live[tower.id] = true
		var node := _tower_nodes.get(tower.id) as MeshInstance3D
		if node == null:
			node = _make_tower(tower)
			_towers_root.add_child(node)
			_tower_nodes[tower.id] = node
		_apply_tower(node, tower)
	_drop_missing(_tower_nodes, live)


func _sync_enemies(enemies: Array) -> void:
	if not _use_meshes():
		return
	var live := {}
	for item in enemies:
		var enemy := item as EnemyState
		if enemy == null:
			continue
		live[enemy.id] = true
		var node := _enemy_nodes.get(enemy.id) as MeshInstance3D
		if node == null:
			node = _make_enemy(enemy)
			_enemies_root.add_child(node)
			_enemy_nodes[enemy.id] = node
		_apply_enemy(node, enemy)
	_drop_missing(_enemy_nodes, live)


func _make_tower(tower: TowerState) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = "Tower%d" % tower.id
	node.mesh = BoxMesh.new()
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.7
	node.material_override = mat
	_apply_tower(node, tower)
	return node


func _apply_tower(node: MeshInstance3D, tower: TowerState) -> void:
	var height := 0.55 + float(tower.tier) * 0.28
	var box := node.mesh as BoxMesh
	if box != null:
		box.size = Vector3(0.55, height, 0.55)
	var mat := node.material_override as StandardMaterial3D
	if mat != null:
		mat.albedo_color = _tower_color(tower.tower_id)
	node.position = cell_to_world(tower.cell) + Vector3(0.0, height * 0.5, 0.0)


func _make_enemy(enemy: EnemyState) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = "Enemy%d" % enemy.id
	node.mesh = CylinderMesh.new()
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.62
	mat.albedo_color = _enemy_color(enemy.enemy_id)
	node.material_override = mat
	_apply_enemy(node, enemy)
	return node


func _apply_enemy(node: MeshInstance3D, enemy: EnemyState) -> void:
	var radius := 0.2
	if enemy.enemy_id == &"boss":
		radius = 0.34
	elif enemy.enemy_id == &"swarm":
		radius = 0.12
	var height := radius * 2.2
	var cyl := node.mesh as CylinderMesh
	if cyl != null:
		cyl.top_radius = radius
		cyl.bottom_radius = radius
		cyl.height = height
	var lift := height * 0.5
	if enemy.is_air:
		lift = 0.85 + height * 0.5
	node.position = point_to_world(enemy.position) + Vector3(0.0, lift, 0.0)


func _place_ghost() -> void:
	if _ghost == null:
		return
	if is_miss(_ghost_cell):
		_ghost.visible = false
		return
	_ghost.visible = true
	_ghost.position = cell_to_world(_ghost_cell) + Vector3(0.0, 0.45, 0.0)
	var mat := _ghost.material_override as StandardMaterial3D
	if mat != null:
		mat.albedo_color = GHOST_OK if _ghost_ok else GHOST_BAD


func _apply_bounds(width: int, height: int) -> void:
	var w := float(maxi(width, 1)) * CELL
	var h := float(maxi(height, 1)) * CELL
	_board_center = Vector3(w * 0.5, 0.0, h * 0.5)
	_bounds_radius = Vector2(w, h).length() * 0.5
	_dist_min = maxf(3.0, _bounds_radius * 0.45)
	_dist_max = maxf(_dist_min + 4.0, _bounds_radius * 5.5)


func _fit_distance(view_size: Vector2) -> float:
	var view := view_size
	if view.x < 2.0 or view.y < 2.0:
		view = Vector2(1280.0, 720.0)
	if _camera == null:
		return clampf(_bounds_radius * 2.15, _dist_min, _dist_max)
	var aspect := view.x / view.y
	var half_v := deg_to_rad(_camera.fov * 0.5)
	var half_h := atan(tan(half_v) * aspect)
	var limit := maxf(minf(half_v, half_h), 0.05)
	var dist := (_bounds_radius + 0.75) / sin(limit) * 1.08
	return clampf(dist, _dist_min, _dist_max)


func _apply_camera() -> void:
	if _camera == null:
		return
	var pitch := deg_to_rad(PITCH_DEG)
	var yaw := _yaw + CAM_YAW
	var offset := Vector3(
		sin(yaw) * cos(pitch),
		sin(pitch),
		cos(yaw) * cos(pitch)
	) * _distance
	_camera.global_position = _focus + offset
	if _camera.global_position.distance_squared_to(_focus) > 0.0001:
		_camera.look_at(_focus, Vector3.UP)


func _tower_color(tower_id: StringName) -> Color:
	match tower_id:
		&"bolt":
			return Color(0.95, 0.82, 0.28, 1)
		&"mortar":
			return Color(0.85, 0.45, 0.22, 1)
		&"frost":
			return Color(0.55, 0.84, 0.95, 1)
		&"flak":
			return Color(0.45, 0.55, 0.72, 1)
		&"beam":
			return Color(0.72, 0.4, 0.9, 1)
		_:
			return Color(0.8, 0.8, 0.82, 1)


func _enemy_color(enemy_id: StringName) -> Color:
	match enemy_id:
		&"grunt":
			return Color(0.75, 0.28, 0.24, 1)
		&"runner":
			return Color(0.9, 0.55, 0.2, 1)
		&"tank":
			return Color(0.35, 0.38, 0.42, 1)
		&"swarm":
			return Color(0.4, 0.7, 0.35, 1)
		&"flyer":
			return Color(0.4, 0.68, 0.95, 1)
		&"boss":
			return Color(0.55, 0.22, 0.58, 1)
		_:
			return Color(0.85, 0.85, 0.85, 1)


func _mat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.88
	return mat


func _drop_missing(nodes: Dictionary, live: Dictionary) -> void:
	var stale: Array = []
	for key in nodes.keys():
		if not live.has(key):
			stale.append(key)
	for key in stale:
		var node: Node = nodes[key]
		nodes.erase(key)
		node.free()


func _clear(node: Node) -> void:
	if node == null:
		return
	for child in node.get_children():
		child.free()
