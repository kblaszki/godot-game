class_name Board3D
extends Node3D

## Isometric table: baker textures on a yaw pivot, camera pitched ~40°.

const PITCH_DEG := 40.0
const CAM_YAW := PI * 0.25
const FOLLOW_LEAN := 0.32
const FOLLOW_POS_RATE := 1.7
const FOLLOW_ROT_RATE := 1.5
const ORBIT_SENS := 0.008
const CARD_H := 8.0
const SKY := Color(0.53, 0.74, 0.92, 1)

const PAWN_COLORS: Array[Color] = [
	Color(0.95, 0.45, 0.4, 1),
	Color(0.4, 0.75, 1.0, 1),
	Color(0.45, 0.9, 0.55, 1),
	Color(0.95, 0.8, 0.35, 1),
]

const MEEPLE_PATHS: Array[String] = [
	"res://games/districts/assets/kenney_boardgame/pieces/meeple_red.png",
	"res://games/districts/assets/kenney_boardgame/pieces/meeple_blue.png",
	"res://games/districts/assets/kenney_boardgame/pieces/meeple_green.png",
	"res://games/districts/assets/kenney_boardgame/pieces/meeple_yellow.png",
]

var _camera: Camera3D
var _pivot: Node3D
var _tiles_root: Node3D
var _buildings_root: Node3D
var _pawns_root: Node3D
var _fx: Node3D
var _tile_roots: Array[Node3D] = []
var _tile_mats: Array[StandardMaterial3D] = []
var _buildings: Array[Node3D] = []
var _building_mats: Array[StandardMaterial3D] = []
var _pips: Array[MeshInstance3D] = []
var _pawn_nodes: Array[Node3D] = []
var _centers: Array[Vector3] = []
var _bounds_radius: float = 400.0
var _distance: float = 1400.0
var _dist_min: float = 280.0
var _dist_max: float = 3200.0
var _focus: Vector3 = Vector3.ZERO
var _shake_offset: Vector3 = Vector3.ZERO
var _follow_space: int = -1
var _auto_orient: bool = false
var _hold_user_camera: bool = false
var _recenter: bool = false
var _orbiting: bool = false
var _panning: bool = false
var _highlight_index: int = -1
var _fit_tween: Tween


func _ready() -> void:
	_build_rig()


func _use_meshes() -> bool:
	## The standard binary's --headless flag does not set the headless feature.
	return not OS.has_feature("headless") and DisplayServer.get_name() != "headless"


func _process(delta: float) -> void:
	if _camera == null or _pivot == null:
		return
	if not _hold_user_camera and not _orbiting and not _panning:
		if _follow_space >= 0 and _follow_space < _centers.size():
			if _auto_orient:
				var yaw_t := 1.0 - exp(-FOLLOW_ROT_RATE * delta)
				_pivot.rotation.y = lerp_angle(_pivot.rotation.y, _yaw_for_side(_side_of(_follow_space)), yaw_t)
			var world_tile := _pivot.to_global(_centers[_follow_space])
			var desired := _pivot.global_position.lerp(world_tile, FOLLOW_LEAN)
			var pos_t := 1.0 - exp(-FOLLOW_POS_RATE * delta)
			_focus = _focus.lerp(desired, pos_t)
		elif _recenter:
			var pos_t := 1.0 - exp(-FOLLOW_POS_RATE * delta)
			_focus = _focus.lerp(_pivot.global_position, pos_t)
			if _focus.distance_to(_pivot.global_position) < 1.5:
				_recenter = false
	_apply_camera()


func setup_match(sim: DistrictSim) -> void:
	_clear_children(_tiles_root)
	_clear_children(_buildings_root)
	_clear_children(_pawns_root)
	_clear_children(_fx)
	_tile_roots.clear()
	_tile_mats.clear()
	_buildings.clear()
	_building_mats.clear()
	_pips.clear()
	_pawn_nodes.clear()
	_centers.clear()
	_bounds_radius = 1.0

	var count := sim.get_config().space_count()
	var absolute := _square_ring_centers(count)
	for center in absolute:
		var reach := Vector2(center.x, center.z).length() + float(DistrictTileBaker.CORNER_SIZE)
		_bounds_radius = maxf(_bounds_radius, reach)
		_centers.append(center)

	_add_ground()
	for i in count:
		_add_tile(i, sim.get_config().space_at(i))
		_add_building_slot(i)
		_add_pip(i)
	for i in sim.get_player_count():
		_add_pawn(i)
	_dist_min = maxf(220.0, _bounds_radius * 0.4)
	_dist_max = maxf(_dist_min + 200.0, _bounds_radius * 5.5)
	_distance = clampf(_bounds_radius * 2.35, _dist_min, _dist_max)
	_focus = _pivot.global_position
	_pivot.rotation.y = 0.0
	sync_from_sim(sim)
	layout_pawns(sim)
	_apply_camera()


func pawn_node(player_id: int) -> Node3D:
	if player_id < 0 or player_id >= _pawn_nodes.size():
		return null
	return _pawn_nodes[player_id]


func pawn_local(player_id: int, space_i: int) -> Vector3:
	if space_i < 0 or space_i >= _centers.size():
		return Vector3.ZERO
	var base := _centers[space_i]
	var spread := Vector3(float(player_id) * 12.0 - 18.0, 0.0, float(player_id % 2) * 10.0 - 4.0)
	return Vector3(base.x, CARD_H + 10.0, base.z) + spread


func snap_pawn(player_id: int, space_i: int) -> void:
	var pawn := pawn_node(player_id)
	if pawn == null:
		return
	pawn.position = pawn_local(player_id, space_i)


func layout_pawns(sim: DistrictSim) -> void:
	for i in _pawn_nodes.size():
		var player := sim.get_player(i)
		_pawn_nodes[i].visible = not player.bankrupt
		snap_pawn(i, player.position)


func sync_from_sim(sim: DistrictSim) -> void:
	var count := mini(sim.get_config().space_count(), _buildings.size())
	for i in count:
		var owner := sim.get_owner(i)
		var color := Color(0.75, 0.75, 0.78, 1)
		if owner >= 0:
			color = PAWN_COLORS[owner % PAWN_COLORS.size()]
		set_building(i, sim.get_build_level(i), color)
		_set_pip(i, owner)


func set_building(space_i: int, level: int, color: Color) -> void:
	if space_i < 0 or space_i >= _buildings.size():
		return
	var node := _buildings[space_i]
	if level <= 0:
		node.visible = false
		node.scale = Vector3.ONE
		return
	var height := 12.0 + float(level) * 18.0
	var mesh_node := node as MeshInstance3D
	if mesh_node != null:
		if space_i < _building_mats.size():
			_building_mats[space_i].albedo_color = color
		var box := mesh_node.mesh as BoxMesh
		if box != null:
			box.size = Vector3(34, height, 34)
	var center := _centers[space_i]
	var inward := center.lerp(Vector3.ZERO, 0.34)
	node.position = Vector3(inward.x, CARD_H + height * 0.5, inward.z)
	node.visible = true
	node.scale = Vector3.ONE


func pop_building(space_i: int, level: int, color: Color) -> void:
	set_building(space_i, level, color)
	if space_i < 0 or space_i >= _buildings.size() or level <= 0:
		return
	var node := _buildings[space_i]
	node.scale = Vector3(1, 0.08, 1)
	var tw := create_tween()
	tw.tween_property(node, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished


func flash_tile(space_i: int) -> void:
	if space_i < 0 or space_i >= _tile_mats.size():
		return
	var mat := _tile_mats[space_i]
	mat.emission_enabled = true
	mat.emission = Color(1, 0.95, 0.75, 1)
	mat.emission_energy_multiplier = 0.55
	var tw := create_tween()
	tw.tween_property(mat, "emission_energy_multiplier", 0.0, 0.22)
	tw.tween_callback(func() -> void:
		if _highlight_index != space_i:
			mat.emission_enabled = false
	)


func pop_tile(space_i: int) -> void:
	if space_i < 0 or space_i >= _tile_roots.size():
		return
	var node := _tile_roots[space_i]
	var tw := create_tween()
	tw.tween_property(node, "scale", Vector3(1.12, 1.12, 1.12), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector3.ONE, 0.16)
	await tw.finished


func burst_at(space_i: int, tint: Color) -> void:
	if not _use_meshes() or space_i < 0 or space_i >= _centers.size() or _fx == null:
		return
	var origin := _centers[space_i] + Vector3(0, CARD_H + 8.0, 0)
	for n in 8:
		var bit := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(6, 6, 6)
		bit.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = tint
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		bit.material_override = mat
		bit.position = origin
		_fx.add_child(bit)
		var angle := TAU * float(n) / 8.0
		var dest := origin + Vector3(cos(angle), 0.35, sin(angle)) * 40.0
		var tw := create_tween()
		tw.tween_property(bit, "position", dest, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(bit, "scale", Vector3(0.15, 0.15, 0.15), 0.28)
		tw.tween_callback(bit.queue_free)


func highlight_space(space_i: int, amount: float) -> void:
	_highlight_index = space_i
	for i in _tile_mats.size():
		var mat := _tile_mats[i]
		if i == space_i:
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.92, 0.65, 1)
			mat.emission_energy_multiplier = 0.08 + 0.28 * clampf(amount, 0.0, 1.0)
		else:
			mat.emission_enabled = false
			mat.emission_energy_multiplier = 0.0


func clear_highlight() -> void:
	_highlight_index = -1
	for mat in _tile_mats:
		mat.emission_enabled = false
		mat.emission_energy_multiplier = 0.0


func set_follow_space(space_i: int) -> void:
	if space_i < 0 or space_i >= _centers.size():
		return
	_follow_space = space_i
	_auto_orient = true
	_hold_user_camera = false
	_recenter = false


func begin_orbit() -> void:
	_orbiting = true
	_panning = false
	_hold_user_camera = true
	_auto_orient = false
	_follow_space = -1
	_recenter = false
	_focus = _pivot.global_position


func orbit_by(delta_x: float) -> void:
	_pivot.rotation.y += delta_x * ORBIT_SENS
	_focus = _pivot.global_position


func end_orbit() -> void:
	_orbiting = false
	_hold_user_camera = false
	_auto_orient = false
	_follow_space = -1
	_recenter = true


func begin_pan() -> void:
	_panning = true
	_orbiting = false
	_hold_user_camera = true
	_auto_orient = false
	_follow_space = -1
	_recenter = false


func pan_by(delta: Vector2, view_size: Vector2) -> void:
	if _camera == null:
		return
	var view_h := maxf(view_size.y, 1.0)
	var world_per_px := (2.0 * _distance * tan(deg_to_rad(_camera.fov * 0.5))) / view_h
	var right := _camera.global_transform.basis.x
	right.y = 0.0
	if right.length_squared() > 0.0001:
		right = right.normalized()
	var forward := -_camera.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() > 0.0001:
		forward = forward.normalized()
	_focus += (-right * delta.x - forward * delta.y) * world_per_px
	_focus.y = _pivot.global_position.y


func end_pan() -> void:
	_panning = false


func zoom_by(factor: float) -> void:
	_hold_user_camera = true
	_auto_orient = false
	_recenter = false
	_distance = clampf(_distance / factor, _dist_min, _dist_max)


func fit(view_size: Vector2) -> void:
	if _pivot == null:
		return
	_hold_user_camera = false
	_recenter = false
	_follow_space = -1
	_auto_orient = false
	_orbiting = false
	_panning = false
	var dist := _fit_distance(view_size)
	if _fit_tween != null and _fit_tween.is_valid():
		_fit_tween.kill()
	_fit_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_fit_tween.tween_property(self, "_distance", dist, 0.5)
	_fit_tween.parallel().tween_property(_pivot, "rotation:y", 0.0, 0.5)
	_fit_tween.parallel().tween_property(self, "_focus", _pivot.global_position, 0.5)


func shake(strength: float) -> void:
	var tw := create_tween()
	for _i in 4:
		var kick := Vector3(randf_range(-1.0, 1.0), randf_range(-0.35, 0.35), randf_range(-1.0, 1.0))
		tw.tween_property(self, "_shake_offset", kick * 14.0 * strength, 0.04)
	tw.tween_property(self, "_shake_offset", Vector3.ZERO, 0.06)
	await tw.finished


func _build_rig() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.84, 0.88, 0.92, 1)
	env.ambient_light_energy = 1.05
	env_node.environment = env
	add_child(env_node)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_energy = 1.15
	sun.light_color = Color(1.0, 0.97, 0.92, 1)
	sun.shadow_enabled = false
	add_child(sun)

	_camera = Camera3D.new()
	_camera.name = "Camera3D"
	_camera.fov = 38.0
	_camera.near = 1.0
	_camera.far = 20000.0
	_camera.current = true
	add_child(_camera)

	_pivot = Node3D.new()
	_pivot.name = "BoardPivot3D"
	add_child(_pivot)

	_tiles_root = Node3D.new()
	_tiles_root.name = "Tiles"
	_pivot.add_child(_tiles_root)
	_buildings_root = Node3D.new()
	_buildings_root.name = "Buildings"
	_pivot.add_child(_buildings_root)
	_pawns_root = Node3D.new()
	_pawns_root.name = "Pawns"
	_pivot.add_child(_pawns_root)
	_fx = Node3D.new()
	_fx.name = "Fx"
	_pivot.add_child(_fx)
	_apply_camera()


func _add_ground() -> void:
	if not _use_meshes():
		return
	var grass := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(9000, 9000)
	grass.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.34, 0.62, 0.34, 1)
	mat.roughness = 1.0
	grass.material_override = mat
	grass.position = Vector3(0, -1.0, 0)
	_pivot.add_child(grass)
	_pivot.move_child(grass, 0)

	var arm := 0.0
	for center in _centers:
		arm = maxf(arm, maxf(absf(center.x), absf(center.z)))
	var inner := maxf(40.0, arm - float(DistrictTileBaker.HEIGHT) * 0.5 - 8.0)
	var plate := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(inner * 2.0, 4.0, inner * 2.0)
	plate.mesh = box
	var plate_mat := StandardMaterial3D.new()
	plate_mat.albedo_color = Color(0.16, 0.46, 0.3, 1)
	plate_mat.roughness = 0.92
	plate.material_override = plate_mat
	plate.position = Vector3(0, 2.0, 0)
	_pivot.add_child(plate)

	_add_stack(_pivot, Vector3(-46, 4.0, 10), 4, Color(0.2, 0.62, 0.38, 1))
	_add_stack(_pivot, Vector3(8, 4.0, -28), 3, Color(0.85, 0.72, 0.28, 1))
	_add_stack(_pivot, Vector3(42, 4.0, 24), 5, Color(0.75, 0.32, 0.28, 1))


func _add_stack(parent: Node3D, at: Vector3, count: int, color: Color) -> void:
	for i in count:
		var bit := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(18, 5, 11)
		bit.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color.lightened(0.04 * float(i))
		mat.roughness = 0.55
		bit.material_override = mat
		bit.position = at + Vector3(0, 2.5 + float(i) * 5.1, 0)
		parent.add_child(bit)


func _add_tile(index: int, space: BoardSpace) -> void:
	var corner := DistrictTileBaker.is_corner_kind(space.kind)
	var size_x := float(DistrictTileBaker.CORNER_SIZE if corner else DistrictTileBaker.WIDTH)
	var size_z := float(DistrictTileBaker.CORNER_SIZE if corner else DistrictTileBaker.HEIGHT)
	var center := _centers[index]
	var root := Node3D.new()
	root.name = "Tile%d" % index
	root.transform = Transform3D(_basis_outward(_side_outward(_side_of(index))), Vector3(center.x, CARD_H, center.z))
	_tiles_root.add_child(root)
	_tile_roots.append(root)
	if not _use_meshes():
		return

	var card := MeshInstance3D.new()
	var card_mesh := BoxMesh.new()
	card_mesh.size = Vector3(size_x - 1.5, CARD_H, size_z - 1.5)
	card.mesh = card_mesh
	var side_mat := StandardMaterial3D.new()
	side_mat.albedo_color = Color(0.94, 0.91, 0.84, 1)
	side_mat.roughness = 0.86
	card.material_override = side_mat
	card.position = Vector3(0, -CARD_H * 0.5, 0)
	root.add_child(card)

	var top := MeshInstance3D.new()
	var face := PlaneMesh.new()
	face.size = Vector2(size_x - 1.0, size_z - 1.0)
	top.mesh = face
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = DistrictTileBaker.bake(space)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	mat.roughness = 0.78
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	top.material_override = mat
	top.position = Vector3(0, 0.4, 0)
	root.add_child(top)
	_tile_mats.append(mat)


func _add_building_slot(index: int) -> void:
	if not _use_meshes():
		var plain := Node3D.new()
		plain.name = "Build%d" % index
		plain.visible = false
		_buildings_root.add_child(plain)
		_buildings.append(plain)
		return
	var node := MeshInstance3D.new()
	node.name = "Build%d" % index
	var box := BoxMesh.new()
	box.size = Vector3(34, 16, 34)
	node.mesh = box
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.62
	node.material_override = mat
	node.visible = false
	_buildings_root.add_child(node)
	_buildings.append(node)
	_building_mats.append(mat)


func _add_pip(index: int) -> void:
	if not _use_meshes():
		return
	var pip := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 5.0
	cyl.bottom_radius = 5.0
	cyl.height = 3.0
	pip.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.roughness = 0.4
	pip.material_override = mat
	pip.visible = false
	var center := _centers[index]
	var inward := center.lerp(Vector3.ZERO, 0.22)
	pip.position = Vector3(inward.x, CARD_H + 2.0, inward.z)
	_buildings_root.add_child(pip)
	_pips.append(pip)


func _set_pip(index: int, owner: int) -> void:
	if index < 0 or index >= _pips.size():
		return
	var pip := _pips[index]
	if owner < 0:
		pip.visible = false
		return
	pip.visible = true
	var mat := pip.material_override as StandardMaterial3D
	if mat != null:
		mat.albedo_color = PAWN_COLORS[owner % PAWN_COLORS.size()]


func _add_pawn(player_id: int) -> void:
	var holder := Node3D.new()
	holder.name = "Pawn%d" % player_id
	if _use_meshes():
		var sprite := Sprite3D.new()
		var path := MEEPLE_PATHS[player_id % MEEPLE_PATHS.size()]
		var tex: Texture2D = load(path) as Texture2D
		if tex != null:
			sprite.texture = tex
		sprite.pixel_size = 0.55
		sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sprite.shaded = false
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.position = Vector3(0, 18, 0)
		sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		holder.add_child(sprite)
	holder.position = pawn_local(player_id, 0)
	_pawns_root.add_child(holder)
	_pawn_nodes.append(holder)


func _apply_camera() -> void:
	if _camera == null:
		return
	_camera.global_position = _focus + _spherical_offset() + _shake_offset
	if _camera.global_position.distance_squared_to(_focus) > 0.01:
		_camera.look_at(_focus, Vector3.UP)


func _spherical_offset() -> Vector3:
	var pitch := deg_to_rad(PITCH_DEG)
	var horiz := cos(pitch) * _distance
	return Vector3(sin(CAM_YAW) * horiz, sin(pitch) * _distance, cos(CAM_YAW) * horiz)


func _fit_distance(view_size: Vector2) -> float:
	var view := view_size
	if view.x < 2.0 or view.y < 2.0:
		view = Vector2(1280, 720)
	var aspect := view.x / view.y
	var half_v := deg_to_rad(_camera.fov * 0.5)
	var half_h := atan(tan(half_v) * aspect)
	var limit := maxf(minf(half_v, half_h), 0.15)
	var dist := (_bounds_radius + 70.0) / sin(limit) * 1.12
	return clampf(dist, _dist_min, _dist_max)


func _yaw_for_side(side: int) -> float:
	var outward := _side_outward(side)
	return CAM_YAW - atan2(outward.x, outward.z)


func _side_of(index: int) -> int:
	var per_side := maxi(_centers.size() / 4, 1)
	return clampi(int(index / per_side), 0, 3)


func _side_outward(side: int) -> Vector3:
	match side:
		0:
			return Vector3(0, 0, 1)
		1:
			return Vector3(1, 0, 0)
		2:
			return Vector3(0, 0, -1)
		_:
			return Vector3(-1, 0, 0)


func _basis_outward(outward: Vector3) -> Basis:
	var z_axis := -outward.normalized()
	var x_axis := z_axis.cross(Vector3.UP)
	if x_axis.length_squared() < 0.0001:
		x_axis = Vector3.RIGHT
	x_axis = x_axis.normalized()
	var y_axis := x_axis.cross(z_axis).normalized()
	return Basis(x_axis, y_axis, z_axis)


func _square_ring_centers(count: int) -> Array[Vector3]:
	var per := maxi(count / 4, 1)
	var edges := maxi(per - 1, 1)
	var edge_w := float(DistrictTileBaker.WIDTH)
	var corner_r := float(DistrictTileBaker.CORNER_SIZE) * 0.5
	var arm := float(edges) * edge_w * 0.5 + corner_r
	var centers: Array[Vector3] = []
	centers.resize(count)
	for i in count:
		var side := int(i / per)
		var slot := i % per
		var x := 0.0
		var z := 0.0
		match side:
			0:
				if slot == 0:
					x = -arm
					z = arm
				else:
					var x0 := -arm + corner_r + edge_w * 0.5
					x = x0 + float(slot - 1) * edge_w
					z = arm
			1:
				if slot == 0:
					x = arm
					z = arm
				else:
					var z0 := arm - corner_r - edge_w * 0.5
					x = arm
					z = z0 - float(slot - 1) * edge_w
			2:
				if slot == 0:
					x = arm
					z = -arm
				else:
					var x0 := arm - corner_r - edge_w * 0.5
					x = x0 - float(slot - 1) * edge_w
					z = -arm
			3:
				if slot == 0:
					x = -arm
					z = -arm
				else:
					var z0 := -arm + corner_r + edge_w * 0.5
					x = -arm
					z = z0 + float(slot - 1) * edge_w
		centers[i] = Vector3(x, 0, z)
	return centers


func _clear_children(node: Node3D) -> void:
	if node == null:
		return
	for child in node.get_children():
		child.free()
