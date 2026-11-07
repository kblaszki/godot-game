class_name CourseCatalog
extends RefCounted

const FAIRWAY_PARK := "fairway_park"


static func build(course_id: String = FAIRWAY_PARK) -> Array[HoleDef]:
	match course_id:
		FAIRWAY_PARK:
			return build_fairway_park()
		_:
			return build_fairway_park()


static func build_fairway_park() -> Array[HoleDef]:
	return [
		_hole_straight(),
		_hole_l_bend(),
		_hole_s_curve(),
		_hole_gate(),
		_hole_bunkers(),
		_hole_damp_pad(),
		_hole_maze(),
		_hole_bank(),
		_hole_signature(),
	]


static func _rect_walls(xmin: float, zmin: float, xmax: float, zmax: float) -> Array[Dictionary]:
	return [
		{"a": Vector2(xmin, zmin), "b": Vector2(xmax, zmin)},
		{"a": Vector2(xmax, zmin), "b": Vector2(xmax, zmax)},
		{"a": Vector2(xmax, zmax), "b": Vector2(xmin, zmax)},
		{"a": Vector2(xmin, zmax), "b": Vector2(xmin, zmin)},
	]


static func _base(id: String, hole_name: String, par: int, tee: Vector3, cup: Vector3, bmin: Vector2, bmax: Vector2) -> HoleDef:
	var h := HoleDef.new()
	h.id = id
	h.name = hole_name
	h.par = par
	h.tee = tee
	h.cup = cup
	h.bounds_min = bmin
	h.bounds_max = bmax
	h.walls = _rect_walls(bmin.x, bmin.y, bmax.x, bmax.y)
	return h


static func _hole_straight() -> HoleDef:
	## Hole 1: open rectangle, cup ahead.
	var h := _base(
		"h1", "Opening Lane", 2,
		Vector3(0, 0, 0), Vector3(0, 0, 6),
		Vector2(-1.2, -0.8), Vector2(1.2, 7.0)
	)
	return h


static func _hole_l_bend() -> HoleDef:
	## Hole 2: L corridor via inner wall.
	var h := _base(
		"h2", "Elbow", 3,
		Vector3(0, 0, 0), Vector3(4, 0, 4),
		Vector2(-1.0, -0.8), Vector2(5.0, 5.0)
	)
	h.walls.append({"a": Vector2(1.2, -0.8), "b": Vector2(1.2, 2.8)})
	h.walls.append({"a": Vector2(1.2, 2.8), "b": Vector2(5.0, 2.8)})
	return h


static func _hole_s_curve() -> HoleDef:
	## Hole 3: two offset barriers forming an S.
	var h := _base(
		"h3", "Serpentine", 3,
		Vector3(0, 0, 0), Vector3(0, 0, 8),
		Vector2(-1.5, -0.8), Vector2(1.5, 9.0)
	)
	h.walls.append({"a": Vector2(-1.5, 2.5), "b": Vector2(0.4, 2.5)})
	h.walls.append({"a": Vector2(-0.4, 5.5), "b": Vector2(1.5, 5.5)})
	return h


static func _hole_gate() -> HoleDef:
	## Hole 4: narrow gate mid-fairway.
	var h := _base(
		"h4", "Needle Gate", 3,
		Vector3(0, 0, 0), Vector3(0, 0, 7),
		Vector2(-1.4, -0.8), Vector2(1.4, 8.0)
	)
	h.walls.append({"a": Vector2(-1.4, 3.5), "b": Vector2(-0.25, 3.5)})
	h.walls.append({"a": Vector2(0.25, 3.5), "b": Vector2(1.4, 3.5)})
	return h


static func _hole_bunkers() -> HoleDef:
	## Hole 5: two circle blockers.
	var h := _base(
		"h5", "Twin Bunkers", 4,
		Vector3(0, 0, 0), Vector3(0, 0, 8),
		Vector2(-2.0, -0.8), Vector2(2.0, 9.0)
	)
	h.blockers = [
		{"center": Vector2(-0.7, 3.0), "radius": 0.55},
		{"center": Vector2(0.7, 5.5), "radius": 0.55},
	]
	return h


static func _hole_damp_pad() -> HoleDef:
	## Hole 6: damp pad (visual ramp later).
	var h := _base(
		"h6", "Uphill Pad", 3,
		Vector3(0, 0, 0), Vector3(0, 0, 7),
		Vector2(-1.3, -0.8), Vector2(1.3, 8.0)
	)
	h.damp_pads = [{"min": Vector2(-1.3, 2.5), "max": Vector2(1.3, 5.0), "factor": 0.35}]
	return h


static func _hole_maze() -> HoleDef:
	## Hole 7: mini maze.
	var h := _base(
		"h7", "Pocket Maze", 4,
		Vector3(0, 0, 0), Vector3(3.5, 0, 6),
		Vector2(-1.0, -0.8), Vector2(4.5, 7.0)
	)
	h.walls.append({"a": Vector2(1.0, -0.8), "b": Vector2(1.0, 3.0)})
	h.walls.append({"a": Vector2(1.0, 4.5), "b": Vector2(1.0, 7.0)})
	h.walls.append({"a": Vector2(1.0, 3.0), "b": Vector2(2.8, 3.0)})
	h.walls.append({"a": Vector2(2.5, 4.5), "b": Vector2(4.5, 4.5)})
	return h


static func _hole_bank() -> HoleDef:
	## Hole 8: cup tucked so a bank helps.
	var h := _base(
		"h8", "Bank Shot", 3,
		Vector3(0, 0, 0), Vector3(3.2, 0, 5.5),
		Vector2(-1.0, -0.8), Vector2(4.0, 6.5)
	)
	h.walls.append({"a": Vector2(1.5, -0.8), "b": Vector2(1.5, 4.0)})
	h.walls.append({"a": Vector2(1.5, 4.0), "b": Vector2(4.0, 4.0)})
	return h


static func _hole_signature() -> HoleDef:
	## Hole 9: narrow bridge fairway + blocker before cup.
	var h := _base(
		"h9", "Signature Bridge", 5,
		Vector3(0, 0, 0), Vector3(0, 0, 10),
		Vector2(-0.7, -0.8), Vector2(0.7, 11.0)
	)
	h.blockers = [{"center": Vector2(0.0, 7.5), "radius": 0.4}]
	h.walls.append({"a": Vector2(-0.7, 4.0), "b": Vector2(-0.35, 4.0)})
	h.walls.append({"a": Vector2(0.35, 4.0), "b": Vector2(0.7, 4.0)})
	return h
