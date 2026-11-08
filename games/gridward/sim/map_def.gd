class_name MapDef
extends RefCounted

## One campaign map. Waypoints are cell indices in cell space (integer x, y),
## not cell centers. buildable is row-major, width * height, 1 = may place, 0 = path.

var id: StringName = &""
var width: int = 0
var height: int = 0
var buildable: PackedByteArray = PackedByteArray()
var waypoints: PackedVector2Array = PackedVector2Array()
var starting_gold: int = 0
var starting_lives: int = 0
var waves: Array[WaveDef] = []
## Tower ids the player may place on this map. The catalog still defines the full roster.
var unlocked_towers: Array[StringName] = []

func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height

func cell_index(cell: Vector2i) -> int:
	return cell.y * width + cell.x

func is_buildable(cell: Vector2i) -> bool:
	if not in_bounds(cell) or buildable.is_empty():
		return false
	return buildable[cell_index(cell)] != 0

## Cells the waypoint polyline occupies. Orthogonal segments include every cell
## along the segment. A diagonal step moves one cell on both axes.
func path_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if waypoints.is_empty():
		return cells
	var current := _waypoint_cell(0)
	cells.append(current)
	for i in range(1, waypoints.size()):
		var target := _waypoint_cell(i)
		while current != target:
			var step := Vector2i(
				clampi(target.x - current.x, -1, 1),
				clampi(target.y - current.y, -1, 1)
			)
			current += step
			cells.append(current)
	return cells

## Marks every in-bounds path cell as not buildable and every other cell as buildable.
func apply_buildable_off_path() -> void:
	buildable = PackedByteArray()
	buildable.resize(width * height)
	buildable.fill(1)
	for cell in path_cells():
		if in_bounds(cell):
			buildable[cell_index(cell)] = 0

func _waypoint_cell(index: int) -> Vector2i:
	var point := waypoints[index]
	return Vector2i(roundi(point.x), roundi(point.y))
