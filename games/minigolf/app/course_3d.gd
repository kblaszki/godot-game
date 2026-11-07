class_name Course3D
extends Node3D

const PITCH_DEG := 40.0
const CAM_YAW := PI * 0.25
const FOLLOW_LEAN := 0.28
const ORBIT_SENS := 0.008
const SKY := Color(0.55, 0.78, 0.95, 1)

var _camera: Camera3D
var _pivot: Node3D
var _course_root: Node3D
var _ball: MeshInstance3D
var _aim_arrow: MeshInstance3D
var _decor: Node3D
var _focus: Vector3 = Vector3.ZERO
var _distance: float = 14.0
var _dist_min: float = 4.0
var _dist_max: float = 40.0
var _bounds_radius: float = 8.0
var _orbiting: bool = false
var _panning: bool = false
var _follow_ball: bool = false
var _shake: Vector3 = Vector3.ZERO
var _ball_display: Vector3 = Vector3.ZERO
var _hole_tee: Vector2 = Vector2.ZERO
var _hole_cup: Vector2 = Vector2.ZERO
const WALL_THICK := 0.1


func _ready() -> void:
	_build_rig()


func is_orbiting() -> bool:
	return _orbiting


func is_panning() -> bool:
	return _panning


func get_camera() -> Camera3D:
	return _camera


## Align BoxMesh local +X with XZ direction (dx, dz).
static func yaw_for_xz_delta(delta: Vector2) -> float:
	return atan2(-delta.y, delta.x)


func _process(delta: float) -> void:
	if _camera == null:
		return
	if _follow_ball and not _orbiting and not _panning:
		var desired := _pivot.global_position.lerp(_ball_display, FOLLOW_LEAN)
		_focus = _focus.lerp(desired, 1.0 - exp(-2.0 * delta))
	_apply_camera()
	if _shake.length() > 0.001:
		_shake = _shake.lerp(Vector3.ZERO, 1.0 - exp(-8.0 * delta))


func setup_hole(hole: HoleDef, show_ramp_visual: bool = false) -> void:
	_clear(_course_root)
	_clear(_decor)
	_hole_tee = hole.tee_xz()
	_hole_cup = hole.cup_xz()
	var bmin := hole.bounds_min
	var bmax := hole.bounds_max
	var size := bmax - bmin
	var center := Vector3((bmin.x + bmax.x) * 0.5, 0.0, (bmin.y + bmax.y) * 0.5)
	_pivot.position = center
	_focus = center
	_bounds_radius = maxf(size.x, size.y) * 0.65 + 2.0
	_distance = _bounds_radius * 2.2

	if _use_meshes():
		_add_fairway(hole, center, size)
		_add_walls(hole)
		_add_blockers(hole)
		_add_cup(hole)
		_add_tee_marker(hole)
		if show_ramp_visual:
			_add_ramp_visual(hole)
		_add_trees(hole)
		if _ball == null:
			_ball = _make_sphere(Color(0.98, 0.98, 1.0, 1), 0.05)
			_ball.name = "Ball"
			_pivot.add_child(_ball)
		if _aim_arrow == null:
			_aim_arrow = _make_arrow()
			_pivot.add_child(_aim_arrow)
	_ball_display = _to_world(hole.tee_xz())
	if _ball != null:
		_ball.position = _pivot.to_local(_ball_display)
	if _aim_arrow != null:
		_aim_arrow.visible = false


func set_ball_pos(xz: Vector2, lerp_t: float = 1.0) -> void:
	var target := _to_world(xz)
	_ball_display = _ball_display.lerp(target, clampf(lerp_t, 0.0, 1.0))
	if _ball != null and _pivot != null:
		_ball.position = _pivot.to_local(_ball_display)


func set_follow_ball(on: bool) -> void:
	_follow_ball = on


func set_aim_dir(dir: Vector2, at_xz: Vector2) -> void:
	if _aim_arrow == null:
		return
	if dir.length_squared() < 0.01:
		_aim_arrow.visible = false
		return
	var d := dir.normalized()
	_aim_arrow.visible = true
	## Shaft along local +X, centered ahead of the ball.
	var tip := at_xz + d * 0.45
	_aim_arrow.position = _pivot.to_local(_to_world(tip)) + Vector3(0, 0.06, 0)
	_aim_arrow.rotation = Vector3(0, yaw_for_xz_delta(d), 0)


func hide_aim() -> void:
	if _aim_arrow != null:
		_aim_arrow.visible = false


func punch_camera(amount: float = 0.15) -> void:
	_shake = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * amount


func fit(view_size: Vector2) -> void:
	if view_size.x < 2.0:
		view_size = Vector2(800, 600)
	var aspect := view_size.x / maxf(view_size.y, 1.0)
	_distance = clampf(_bounds_radius * (2.55 / minf(aspect, 1.35)), _dist_min, _dist_max)
	_pivot.rotation.y = 0.0
	## Bias focus toward tee so the putt starts in the lower half of the frame.
	var tee_w := _to_world(_hole_tee)
	var cup_w := _to_world(_hole_cup)
	var mid := (tee_w + cup_w) * 0.5
	_focus = mid.lerp(tee_w, 0.35)
	if _pivot != null:
		_focus = _focus.lerp(_pivot.global_position, 0.25)
	_follow_ball = false
	_apply_camera()


func begin_orbit() -> void:
	_orbiting = true
	_follow_ball = false


func end_orbit() -> void:
	_orbiting = false


func begin_pan() -> void:
	_panning = true
	_follow_ball = false


func end_pan() -> void:
	_panning = false


func orbit(delta_x: float) -> void:
	_pivot.rotation.y += delta_x * ORBIT_SENS


func pan(delta: Vector2) -> void:
	var right := Vector3(1, 0, 0).rotated(Vector3.UP, _pivot.rotation.y + CAM_YAW)
	var forward := Vector3(0, 0, -1).rotated(Vector3.UP, _pivot.rotation.y + CAM_YAW)
	_focus += (right * -delta.x + forward * -delta.y) * (_distance * 0.0015)


func dolly(factor: float) -> void:
	_distance = clampf(_distance / factor, _dist_min, _dist_max)


func _build_rig() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.9, 0.95, 1)
	env.ambient_light_energy = 0.7
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)

	_pivot = Node3D.new()
	_pivot.name = "BoardPivot3D"
	add_child(_pivot)
	_course_root = Node3D.new()
	_course_root.name = "Course"
	_pivot.add_child(_course_root)
	_decor = Node3D.new()
	_decor.name = "Decor"
	_pivot.add_child(_decor)

	_camera = Camera3D.new()
	_camera.name = "Camera3D"
	_camera.fov = 42.0
	add_child(_camera)
	_apply_camera()


func _apply_camera() -> void:
	var pitch := deg_to_rad(PITCH_DEG)
	var yaw := _pivot.rotation.y + CAM_YAW
	var offset := Vector3(
		sin(yaw) * cos(pitch),
		sin(pitch),
		cos(yaw) * cos(pitch)
	) * _distance
	_camera.global_position = _focus + offset + _shake
	_camera.look_at(_focus, Vector3.UP)


func _use_meshes() -> bool:
	return not OS.has_feature("headless") and DisplayServer.get_name() != "headless"


func _to_world(xz: Vector2) -> Vector3:
	return Vector3(xz.x, 0.04, xz.y)


func _add_fairway(hole: HoleDef, center: Vector3, size: Vector2) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(size.x, 0.08, size.y)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.28, 0.62, 0.32, 1)
	mesh.material_override = mat
	mesh.position = _pivot.to_local(center) + Vector3(0, -0.04, 0)
	_course_root.add_child(mesh)


func _add_walls(hole: HoleDef) -> void:
	for wall in hole.walls:
		var a: Vector2 = wall["a"]
		var b: Vector2 = wall["b"]
		var delta := b - a
		var length := delta.length()
		if length < 0.01:
			continue
		var dir := delta / length
		## Inset along outward-ish normal so the face sits on the segment, not straddling tee.
		var n := Vector2(-dir.y, dir.x)
		var mid := (a + b) * 0.5 + n * (WALL_THICK * 0.5)
		## Prefer normal pointing outside the fairway AABB when possible.
		var center_xz := (hole.bounds_min + hole.bounds_max) * 0.5
		if (mid - center_xz).dot(n) < 0.0:
			n = -n
			mid = (a + b) * 0.5 + n * (WALL_THICK * 0.5)
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(length, 0.35, WALL_THICK)
		mesh.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.82, 0.78, 0.7, 1)
		mesh.material_override = mat
		mesh.position = _pivot.to_local(Vector3(mid.x, 0.15, mid.y))
		mesh.rotation.y = yaw_for_xz_delta(delta)
		_course_root.add_child(mesh)


func _add_blockers(hole: HoleDef) -> void:
	for blocker in hole.blockers:
		var c: Vector2 = blocker["center"]
		var r: float = float(blocker["radius"])
		var mesh := _make_cylinder(Color(0.75, 0.55, 0.28, 1), r, 0.25)
		mesh.position = _pivot.to_local(Vector3(c.x, 0.12, c.y))
		_course_root.add_child(mesh)


func _add_cup(hole: HoleDef) -> void:
	var cup := hole.cup_xz()
	var hole_mesh := _make_cylinder(Color(0.08, 0.08, 0.1, 1), 0.08, 0.02)
	hole_mesh.position = _pivot.to_local(Vector3(cup.x, 0.01, cup.y))
	_course_root.add_child(hole_mesh)
	var flag := MeshInstance3D.new()
	var pole := BoxMesh.new()
	pole.size = Vector3(0.02, 0.6, 0.02)
	flag.mesh = pole
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.2, 0.2, 1)
	flag.material_override = mat
	flag.position = _pivot.to_local(Vector3(cup.x, 0.3, cup.y))
	_course_root.add_child(flag)


func _add_tee_marker(hole: HoleDef) -> void:
	var tee := hole.tee_xz()
	var m := _make_cylinder(Color(0.55, 0.72, 0.45, 1), 0.14, 0.015)
	m.position = _pivot.to_local(Vector3(tee.x, 0.008, tee.y))
	_course_root.add_child(m)


func _add_ramp_visual(hole: HoleDef) -> void:
	for pad in hole.damp_pads:
		var pmin: Vector2 = pad["min"]
		var pmax: Vector2 = pad["max"]
		var mid := (pmin + pmax) * 0.5
		var size := pmax - pmin
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(size.x, 0.12, size.y)
		mesh.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.45, 0.7, 0.4, 1)
		mesh.material_override = mat
		mesh.position = _pivot.to_local(Vector3(mid.x, 0.02, mid.y))
		mesh.rotation_degrees.x = -8.0
		_course_root.add_child(mesh)


func _add_trees(hole: HoleDef) -> void:
	var bmin := hole.bounds_min
	var bmax := hole.bounds_max
	var spots: Array[Vector2] = [
		Vector2(bmin.x - 1.2, bmin.y + 1.0),
		Vector2(bmax.x + 1.2, bmin.y + 2.0),
		Vector2(bmin.x - 1.0, bmax.y - 1.0),
		Vector2(bmax.x + 1.0, bmax.y - 2.0),
	]
	for s in spots:
		var trunk := _make_cylinder(Color(0.4, 0.25, 0.12, 1), 0.08, 0.5)
		trunk.position = _pivot.to_local(Vector3(s.x, 0.25, s.y))
		_decor.add_child(trunk)
		var crown := _make_sphere(Color(0.2, 0.5, 0.25, 1), 0.35)
		crown.position = _pivot.to_local(Vector3(s.x, 0.7, s.y))
		_decor.add_child(crown)


func _make_sphere(color: Color, radius: float) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	return mesh


func _make_cylinder(color: Color, radius: float, height: float) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	mesh.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh.material_override = mat
	return mesh


func _make_arrow() -> MeshInstance3D:
	## Elongated on local +X; yaw_for_xz_delta aims it on the fairway.
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.9, 0.035, 0.07)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.15, 1)
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.45, 0.05, 1)
	mat.emission_energy_multiplier = 0.4
	mesh.material_override = mat
	return mesh


func _clear(node: Node3D) -> void:
	if node == null:
		return
	for child in node.get_children():
		child.queue_free()
