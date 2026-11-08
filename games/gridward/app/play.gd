extends Control

const CLICK_DRAG_PX := 6.0

var _map: MapDef
var _sim: GridwardSim
var _user_camera: bool = false
var _drag_last: Vector2 = Vector2.ZERO
var _lmb_pressed: bool = false
var _lmb_dragged: bool = false
var _lmb_press_pos: Vector2 = Vector2.ZERO

@onready var _svc: SubViewportContainer = $BoardRoot/SubViewportContainer
@onready var _viewport: SubViewport = $BoardRoot/SubViewportContainer/SubViewport
@onready var _board: GridwardBoard3D = $BoardRoot/SubViewportContainer/SubViewport/Board3D


func _ready() -> void:
	_map = GridwardCatalog.build_meadow()
	_sim = GridwardSim.new(_map, GridwardCatalog.new(), 1)
	if OS.has_feature("headless") or DisplayServer.get_name() == "headless":
		_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	else:
		_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_svc.gui_input.connect(_on_board_gui_input)
	_svc.resized.connect(_on_board_resized)
	_svc.mouse_exited.connect(_clear_ghost)
	_board.sync_from_sim(_sim)
	_board.fit(_svc.size)


func _process(_delta: float) -> void:
	if _sim != null and _board != null:
		_board.sync_from_sim(_sim)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if (event as InputEventKey).keycode == KEY_F and _board != null:
			_user_camera = false
			_board.fit(_svc.size)
			get_viewport().set_input_as_handled()


func _on_board_resized() -> void:
	if _user_camera or _board == null:
		return
	if _board.is_orbiting() or _board.is_panning():
		return
	if _svc.size.x < 2.0 or _svc.size.y < 2.0:
		return
	_board.fit(_svc.size)


func _on_board_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_lmb_pressed = true
				_lmb_dragged = false
				_lmb_press_pos = mb.position
				_drag_last = mb.position
			else:
				_lmb_pressed = false
				_lmb_dragged = false
				_board.end_orbit()
			_svc.accept_event()
		elif mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			if mb.pressed:
				_user_camera = true
				_board.begin_pan()
				_drag_last = mb.position
			else:
				_board.end_pan()
			_svc.accept_event()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_user_camera = true
			_board.dolly(1.1)
			_svc.accept_event()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_user_camera = true
			_board.dolly(1.0 / 1.1)
			_svc.accept_event()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		var delta := mm.position - _drag_last
		_drag_last = mm.position
		if _lmb_pressed and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if not _lmb_dragged and mm.position.distance_to(_lmb_press_pos) >= CLICK_DRAG_PX:
				_lmb_dragged = true
				_user_camera = true
				_board.begin_orbit()
			if _lmb_dragged:
				_board.orbit(delta.x)
			_svc.accept_event()
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			_board.pan(delta)
			_svc.accept_event()
		elif not _lmb_dragged and not _board.is_panning():
			_update_ghost(mm.position)


func _update_ghost(local: Vector2) -> void:
	var vp := _viewport_pos(local)
	if not is_finite(vp.x):
		_clear_ghost()
		return
	var cell := _board.cell_at_screen(vp)
	if GridwardBoard3D.is_miss(cell) or _map == null or not _map.in_bounds(cell):
		_clear_ghost()
		return
	_board.set_ghost(cell, _cell_open(cell))


func _clear_ghost() -> void:
	if _board != null:
		_board.set_ghost(GridwardBoard3D.MISS_CELL, false)


func _cell_open(cell: Vector2i) -> bool:
	if _map == null or not _map.is_buildable(cell):
		return false
	for item in _sim.get_towers():
		var tower := item as TowerState
		if tower != null and tower.cell == cell:
			return false
	return true


func _viewport_pos(local: Vector2) -> Vector2:
	var view := _svc.size
	if view.x < 2.0 or view.y < 2.0:
		return Vector2(INF, INF)
	return Vector2(
		local.x / view.x * float(_viewport.size.x),
		local.y / view.y * float(_viewport.size.y)
	)
