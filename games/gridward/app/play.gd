extends Control

const PAUSE_PATH := "res://games/gridward/app/pause_menu.tscn"
const RESULTS_PATH := "res://games/gridward/app/results.tscn"
const ICON_SHEET_PNG := "res://games/gridward/assets/pxl/icons.png"
const ICON_SHEET_JSON := "res://games/gridward/assets/pxl/icons.json"
const CLICK_DRAG_PX := 6.0

const TOWER_ACTIONS: Array[StringName] = [
	&"gridward_tower_1",
	&"gridward_tower_2",
	&"gridward_tower_3",
	&"gridward_tower_4",
	&"gridward_tower_5",
]

const TARGET_MODES: Array[StringName] = [
	TowerState.TARGET_FIRST,
	TowerState.TARGET_LAST,
	TowerState.TARGET_CLOSEST,
	TowerState.TARGET_STRONGEST,
	TowerState.TARGET_WEAKEST,
]

var _map: MapDef
var _sim: GridwardSim
var _sim_bound: bool = false
var _difficulty: StringName = GridwardConfig.DIFF_NORMAL
var _outcome_sent: bool = false
var _keys: InputState = InputState.new()
var _ui_config: GridwardConfig = GridwardConfig.new()
var _build_group: ButtonGroup = ButtonGroup.new()
var _build_buttons: Array[Button] = []
var _selected_type: StringName = &""
var _selected_entity: int = -1
var _speed_2x: bool = false
var _syncing_ui: bool = false
var _user_camera: bool = false
var _drag_last: Vector2 = Vector2.ZERO
var _lmb_pressed: bool = false
var _lmb_dragged: bool = false
var _lmb_press_pos: Vector2 = Vector2.ZERO
var _hovering: bool = false
var _hover_local: Vector2 = Vector2.ZERO
var _skip_sim_steps: int = 0
var _icon_textures: Dictionary = {}
var _shake_enabled: bool = true
var _tutorial: Label
var _shake_button: Button

@onready var _svc: SubViewportContainer = $BoardRoot/SubViewportContainer
@onready var _viewport: SubViewport = $BoardRoot/SubViewportContainer/SubViewport
@onready var _board: GridwardBoard3D = $BoardRoot/SubViewportContainer/SubViewport/Board3D
@onready var _lives_gold: PanelContainer = $LivesGold
@onready var _lives: Label = $LivesGold/Margin/Column/Lives
@onready var _gold: Label = $LivesGold/Margin/Column/Gold
@onready var _wave_card: PanelContainer = $WaveCard
@onready var _wave: Label = $WaveCard/Margin/Column/Wave
@onready var _speed: Button = $WaveCard/Margin/Column/Speed
@onready var _tower_panel: PanelContainer = $TowerPanel
@onready var _tower_title: Label = $TowerPanel/Margin/Column/Title
@onready var _upgrade: Button = $TowerPanel/Margin/Column/Upgrade
@onready var _sell: Button = $TowerPanel/Margin/Column/Sell
@onready var _targeting: OptionButton = $TowerPanel/Margin/Column/Targeting
@onready var _bottom_dock: PanelContainer = $BottomDock
@onready var _preview: Label = $BottomDock/Margin/Column/Preview
@onready var _build_bar: HBoxContainer = $BottomDock/Margin/Column/ActionRow/BuildBar
@onready var _start: Button = $BottomDock/Margin/Column/ActionRow/StartWave
@onready var _menu: Button = $BottomDock/Margin/Column/ActionRow/Menu
@onready var _audio: GridwardAudio = $GridwardAudio


func bind_sim(sim: GridwardSim, map: MapDef) -> void:
	_sim = sim
	_map = map
	_sim_bound = true
	_outcome_sent = false
	if is_node_ready():
		_selected_type = _default_type()
		_after_command()


func get_sim() -> GridwardSim:
	return _sim


func is_speed_2x() -> bool:
	return _speed_2x


func is_screen_shake_enabled() -> bool:
	return _shake_enabled


func set_screen_shake(enabled: bool) -> void:
	_shake_enabled = enabled
	if _board != null:
		_board.set_shake_enabled(enabled)
	_refresh_shake_button()


func tutorial_text() -> String:
	if _map == null or _sim == null or _map.id != GridwardCatalog.MEADOW:
		return ""
	return meadow_hint(_sim.get_wave_index(), _sim.get_phase(), _sim.get_towers().is_empty())


## Meadow only. Teach a wave, then the next wave tests it. Other phases stay short.
static func meadow_hint(wave_index: int, phase: int, no_towers: bool) -> String:
	if phase == GridwardSim.Phase.VICTORY or phase == GridwardSim.Phase.DEFEAT:
		return ""
	if phase == GridwardSim.Phase.WAVE_CLEAR:
		return "Wave clear. Place or upgrade, then start the next wave."
	match wave_index:
		0:
			if phase == GridwardSim.Phase.BUILD and no_towers:
				return "Teach: click grass beside the path to place a Bolt. It fires by itself."
			if phase == GridwardSim.Phase.BUILD:
				return "Teach: press Start Wave. Four slow grunts walk the lane."
			return "Grunts are slow. The bolt fires on its own."
		1:
			return "Test: six grunts. Hold the lane with the bolt you placed."
		2:
			if phase == GridwardSim.Phase.WAVE:
				return "Runners are faster than grunts. Bolts only hit what is in range."
			return "Teach: runners are faster. A second Bolt covers more of the path."
		3:
			return "Test: grunts, then runners. One lane, two speeds."
		4:
			return "Rest: wider gaps. Upgrade the selected Bolt when you can pay."
		5:
			return "Test: a runner rush. Keep the path inside bolt range."
		6:
			return "Test: grunts and runners together. Cover the lane before you start."
		7:
			return "Test: a grunt pack. Damage along the path beats one late shot."
		8:
			return "Test: runners only. Each leak costs a life."
		9:
			return "Last: grunts and runners. Clear Meadow to open Bend."
		_:
			return ""


func toggle_speed() -> void:
	_speed_2x = not _speed_2x
	_refresh_hud()


func _ready() -> void:
	_ensure_input_map()
	if not _sim_bound:
		_begin_selected_match()
	if OS.has_feature("headless") or DisplayServer.get_name() == "headless":
		_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	else:
		_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_svc.gui_input.connect(_on_board_gui_input)
	_svc.resized.connect(_on_board_resized)
	_svc.mouse_exited.connect(_clear_ghost)
	_apply_styles()
	_fill_targeting()
	_speed.pressed.connect(toggle_speed)
	_start.pressed.connect(_on_start_wave)
	_menu.pressed.connect(_open_pause)
	_upgrade.pressed.connect(_upgrade_selected)
	_sell.pressed.connect(_sell_selected)
	_build_tower_buttons()
	_build_shake_toggle()
	_build_tutorial()
	_selected_type = _default_type()
	_board.set_shake_enabled(_shake_enabled)
	_board.sync_from_sim(_sim)
	_board.fit(_svc.size)
	_refresh_hud()


func _process(_delta: float) -> void:
	if _sim == null:
		return
	_sample_input()
	_advance_sim()


func _input(event: InputEvent) -> void:
	_ensure_input_map()
	if _event_is_play_key(event):
		get_viewport().set_input_as_handled()


func _on_build_pressed(tower_id: StringName) -> void:
	if _syncing_ui:
		return
	_selected_type = tower_id
	_refresh_hud()
	_refresh_ghost()


func _on_start_wave() -> void:
	if _sim == null:
		return
	_sim.start_wave()
	_after_command()


func place_selected_at(cell: Vector2i) -> int:
	if _sim == null or _selected_type == &"":
		return -1
	var id := _sim.place_tower(cell, _selected_type)
	if id >= 0:
		_selected_entity = id
	_after_command()
	return id


func _advance_sim() -> void:
	if _sim == null:
		return
	var count := 2 if _speed_2x else 1
	var stepped := false
	for _i in count:
		if _skip_sim_steps > 0:
			_skip_sim_steps -= 1
			continue
		_sim.step()
		stepped = true
		_dispatch_events(_sim.drain_events())
	if stepped:
		_refresh_hud()
		_refresh_ghost()
	_present_outcome()


func _sample_input() -> void:
	_keys.begin_frame()
	_keys.set_action(&"gridward_start_wave", Input.is_action_pressed("gridward_start_wave"))
	_keys.set_action(&"gridward_speed", Input.is_action_pressed("gridward_speed"))
	_keys.set_action(&"gridward_fit", Input.is_action_pressed("gridward_fit"))
	_keys.set_action(&"ui_cancel", Input.is_action_pressed("ui_cancel"))
	for action in TOWER_ACTIONS:
		_keys.set_action(action, Input.is_action_pressed(action))
	if _keys.is_action_just_pressed(&"ui_cancel"):
		_open_pause()
	if _keys.is_action_just_pressed(&"gridward_start_wave"):
		_on_start_wave()
	if _keys.is_action_just_pressed(&"gridward_speed"):
		toggle_speed()
	if _keys.is_action_just_pressed(&"gridward_fit"):
		_fit_camera()
	for i in TOWER_ACTIONS.size():
		if _keys.is_action_just_pressed(TOWER_ACTIONS[i]):
			_on_build_pressed(GridwardCatalog.TOWER_IDS[i])


func _open_pause() -> void:
	_submit(SceneRequest.push(PAUSE_PATH))


func _fit_camera() -> void:
	if _board == null:
		return
	_user_camera = false
	_board.fit(_svc.size)


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
				var was_drag := _lmb_dragged
				_lmb_pressed = false
				_lmb_dragged = false
				_board.end_orbit()
				if not was_drag:
					_pick_cell(mb.position)
			_svc.accept_event()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			if not mb.pressed:
				_sell_from_pointer(mb.position)
			_svc.accept_event()
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
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
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			_board.pan(delta)
			_svc.accept_event()
		elif not _lmb_dragged and not _board.is_panning():
			_update_ghost(mm.position)


func _pick_cell(local: Vector2) -> void:
	var cell := _cell_from_local(local)
	if GridwardBoard3D.is_miss(cell):
		return
	var tower := _tower_at(cell)
	if tower != null:
		_selected_entity = tower.id
		_after_command()
		return
	place_selected_at(cell)


func _sell_from_pointer(local: Vector2) -> void:
	var cell := _cell_from_local(local)
	if not GridwardBoard3D.is_miss(cell):
		var tower := _tower_at(cell)
		if tower != null:
			_selected_entity = tower.id
	_sell_selected()


func _upgrade_selected() -> void:
	if _sim == null or _selected_entity < 0:
		return
	_sim.upgrade_tower(_selected_entity)
	_after_command()


func _sell_selected() -> void:
	if _sim == null or _selected_entity < 0:
		return
	if _sim.sell_tower(_selected_entity):
		_selected_entity = -1
	_after_command()


func _on_targeting_selected(index: int) -> void:
	if _syncing_ui or _sim == null or _selected_entity < 0:
		return
	if index < 0 or index >= TARGET_MODES.size():
		return
	_sim.set_targeting(_selected_entity, TARGET_MODES[index])
	_after_command()


func _after_command() -> void:
	var events: Array = []
	if _sim != null:
		events = _sim.drain_events()
	_dispatch_events(events)
	_refresh_hud()
	_refresh_ghost()
	_present_outcome()


func _dispatch_events(events: Array) -> void:
	var flashes: Array[int] = []
	var killed := {}
	for item in events:
		var event: Dictionary = item
		if event.is_empty():
			continue
		var reaction := GridwardAudio.reaction(event)
		if _audio != null:
			_audio.play_cue(reaction["cue"], float(reaction["volume"]))
		var trauma := float(reaction["trauma"])
		if trauma > 0.0 and _board != null:
			_board.add_trauma(trauma)
		var stop := int(reaction["hit_stop"])
		if stop > _skip_sim_steps:
			_skip_sim_steps = stop
		_collect_vfx(event, StringName(reaction["vfx"]), flashes, killed)
	_sync_board()
	if _board == null:
		return
	for id in flashes:
		if not killed.has(id):
			_board.flash_enemy(id)


func _collect_vfx(event: Dictionary, vfx: StringName, flashes: Array[int], killed: Dictionary) -> void:
	if _board == null or vfx == &"":
		return
	var entity_id := int(event.get("id", -1))
	match vfx:
		&"hit_flash":
			flashes.append(entity_id)
		&"death_pop":
			killed[entity_id] = true
			_board.pop_enemy(entity_id, StringName(event.get("enemy_id", &"")))
		&"tracer":
			_pulse_tracer(event)
		&"impact":
			var point: Vector2 = event.get("position", Vector2.ZERO)
			_board.burst_impact(point, float(event.get("splash_radius", 0.0)))


func _pulse_tracer(event: Dictionary) -> void:
	if StringName(event.get("kind", &"")) == TowerDef.KIND_PROJECTILE:
		return
	var tower := _tower_entity(int(event.get("id", -1)))
	if tower == null or _board == null:
		return
	var target := _board.enemy_anchor(int(event.get("target_id", -1)))
	if not is_finite(target.x):
		return
	var origin := GridwardBoard3D.cell_to_world(tower.cell) + Vector3(0.0, 0.7, 0.0)
	_board.pulse_shot(origin, target, tower.tower_id)


func _sync_board() -> void:
	if is_node_ready() and _board != null and _sim != null:
		_board.sync_from_sim(_sim)


func _update_ghost(local: Vector2) -> void:
	_hovering = true
	_hover_local = local
	var cell := _cell_from_local(local)
	if _board == null or GridwardBoard3D.is_miss(cell) or _map == null or not _map.in_bounds(cell):
		if _board != null:
			_board.set_ghost(GridwardBoard3D.MISS_CELL, false)
		return
	_board.set_ghost(cell, _cell_placeable(cell))


func _refresh_ghost() -> void:
	if _hovering:
		_update_ghost(_hover_local)


func _clear_ghost() -> void:
	_hovering = false
	if _board != null:
		_board.set_ghost(GridwardBoard3D.MISS_CELL, false)


func _cell_placeable(cell: Vector2i) -> bool:
	if _sim == null or _map == null or _selected_type == &"":
		return false
	if not _commands_open() or not _map.is_buildable(cell):
		return false
	if not _map.unlocked_towers.has(_selected_type) or _tower_at(cell) != null:
		return false
	var definition := GridwardCatalog.tower(_selected_type)
	if definition == null or _sim.get_gold() < definition.cost:
		return false
	return true


func _cell_from_local(local: Vector2) -> Vector2i:
	var vp := _viewport_pos(local)
	if _board == null or not is_finite(vp.x):
		return GridwardBoard3D.MISS_CELL
	return _board.cell_at_screen(vp)


func _tower_at(cell: Vector2i) -> TowerState:
	if _sim == null:
		return null
	for item in _sim.get_towers():
		var tower := item as TowerState
		if tower != null and tower.cell == cell:
			return tower
	return null


func _tower_entity(entity_id: int) -> TowerState:
	if _sim == null or entity_id < 0:
		return null
	for item in _sim.get_towers():
		var tower := item as TowerState
		if tower != null and tower.id == entity_id:
			return tower
	return null


func _find_selected_tower() -> TowerState:
	if _sim == null or _selected_entity < 0:
		return null
	for item in _sim.get_towers():
		var tower := item as TowerState
		if tower != null and tower.id == _selected_entity:
			return tower
	_selected_entity = -1
	return null


func _commands_open() -> bool:
	if _sim == null:
		return false
	var phase := _sim.get_phase()
	return phase == GridwardSim.Phase.BUILD or phase == GridwardSim.Phase.WAVE


func _viewport_pos(local: Vector2) -> Vector2:
	var view := _svc.size
	if view.x < 2.0 or view.y < 2.0:
		return Vector2(INF, INF)
	return Vector2(
		local.x / view.x * float(_viewport.size.x),
		local.y / view.y * float(_viewport.size.y)
	)


func _default_type() -> StringName:
	if _map != null:
		for tower_id in GridwardCatalog.TOWER_IDS:
			if _map.unlocked_towers.has(tower_id):
				return tower_id
	if GridwardCatalog.TOWER_IDS.is_empty():
		return &""
	return GridwardCatalog.TOWER_IDS[0]


func _build_tower_buttons() -> void:
	_load_tower_icons()
	var index := 0
	for tower_id in GridwardCatalog.TOWER_IDS:
		index += 1
		var button := Button.new()
		var definition := GridwardCatalog.tower(tower_id)
		var cost := 0 if definition == null else definition.cost
		button.text = "%d %s %d" % [index, str(tower_id).capitalize(), cost]
		button.toggle_mode = true
		button.button_group = _build_group
		button.set_meta("tower_id", tower_id)
		button.custom_minimum_size = Vector2(0, 40)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_build_pressed.bind(tower_id))
		button.focus_mode = Control.FOCUS_ALL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		var icon: Texture2D = _icon_textures.get(tower_id)
		if icon != null:
			button.icon = icon
			button.expand_icon = false
			button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_style_button(button, Color(0.18, 0.32, 0.28, 1), false)
		_build_bar.add_child(button)
		_build_buttons.append(button)


func _load_tower_icons() -> void:
	_icon_textures.clear()
	if not ResourceLoader.exists(ICON_SHEET_PNG) or not FileAccess.file_exists(ICON_SHEET_JSON):
		return
	var tex := load(ICON_SHEET_PNG) as Texture2D
	if tex == null:
		return
	var sheet := PxlSheet.parse(FileAccess.get_file_as_string(ICON_SHEET_JSON))
	if not sheet.is_valid():
		return
	for tower_id in GridwardCatalog.TOWER_IDS:
		var rect := sheet.frame_rect(tower_id)
		if rect.size.x <= 0 or rect.size.y <= 0:
			continue
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(rect)
		atlas.filter_clip = true
		_icon_textures[tower_id] = atlas


func _build_shake_toggle() -> void:
	var button := Button.new()
	button.name = "Shake"
	button.custom_minimum_size = Vector2(0, 36)
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(_toggle_shake)
	_style_button(button, Color(0.18, 0.32, 0.42, 1), false)
	_speed.get_parent().add_child(button)
	_shake_button = button
	_wave_card.offset_bottom = 160.0
	_refresh_shake_button()


func _toggle_shake() -> void:
	set_screen_shake(not _shake_enabled)


func _refresh_shake_button() -> void:
	if _shake_button == null:
		return
	_shake_button.text = "Shake On" if _shake_enabled else "Shake Off"


func _build_tutorial() -> void:
	var panel := PanelContainer.new()
	panel.name = "TutorialHint"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.offset_left = -280.0
	panel.offset_right = 280.0
	panel.offset_top = 16.0
	panel.offset_bottom = 96.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	var label := Label.new()
	label.name = "Text"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.96, 0.97, 1, 1))
	panel.add_child(label)
	add_child(panel)
	_style_panel(panel, Color(0.07, 0.1, 0.09, 0.92))
	_tutorial = label


func _refresh_tutorial() -> void:
	if _tutorial == null:
		return
	var text := tutorial_text()
	_tutorial.text = text
	var panel := _tutorial.get_parent() as CanvasItem
	if panel != null:
		panel.visible = text != ""


func _fill_targeting() -> void:
	for mode in TARGET_MODES:
		_targeting.add_item(str(mode).capitalize())
	_targeting.item_selected.connect(_on_targeting_selected)


func _refresh_hud() -> void:
	if not is_node_ready() or _sim == null:
		return
	_lives.text = "Lives %d" % _sim.get_lives()
	_gold.text = "Gold %d" % _sim.get_gold()
	var total := 0 if _map == null else _map.waves.size()
	var shown := _sim.get_wave_index() + 1
	if total > 0:
		shown = mini(shown, total)
	_wave.text = "Wave %d/%d" % [shown, total]
	_speed.text = "2x" if _speed_2x else "1x"
	_syncing_ui = true
	for button in _build_buttons:
		var tower_id: StringName = button.get_meta("tower_id")
		var unlocked := _map != null and _map.unlocked_towers.has(tower_id)
		button.disabled = not unlocked
		button.button_pressed = tower_id == _selected_type
	_syncing_ui = false
	_refresh_start()
	_refresh_tower_panel()
	_refresh_tutorial()


func _refresh_start() -> void:
	var phase := _sim.get_phase()
	if phase == GridwardSim.Phase.VICTORY:
		_preview.text = "Victory"
		_start.text = "Start Wave"
		_start.disabled = true
		return
	if phase == GridwardSim.Phase.DEFEAT:
		_preview.text = "Defeat"
		_start.text = "Start Wave"
		_start.disabled = true
		return
	_preview.text = _wave_blurb()
	if phase == GridwardSim.Phase.BUILD and _sim.can_early_call():
		_start.text = "Early Call +%d" % _sim.early_call_bonus()
		_start.disabled = false
		return
	var waves_left := _map != null and _sim.get_wave_index() < _map.waves.size()
	if phase == GridwardSim.Phase.BUILD and waves_left and _sim.get_lives() > 0:
		_start.text = "Start Wave"
		_start.disabled = false
		return
	_start.text = "Start Wave"
	_start.disabled = true


func _wave_blurb() -> String:
	if _map == null or _sim == null:
		return ""
	var index := _sim.get_wave_index()
	if index < 0 or index >= _map.waves.size():
		return "No wave"
	var parts := PackedStringArray()
	for entry in _map.waves[index].entries:
		parts.append("%d %s" % [int(entry["count"]), str(entry["enemy_id"])])
	var body := ", ".join(parts)
	var phase := _sim.get_phase()
	if phase == GridwardSim.Phase.WAVE or phase == GridwardSim.Phase.WAVE_CLEAR:
		return "Now: %s" % body
	return "Next: %s" % body


func _refresh_tower_panel() -> void:
	var tower := _find_selected_tower()
	_tower_panel.visible = tower != null
	if tower == null:
		return
	_tower_title.text = "%s  T%d" % [str(tower.tower_id).capitalize(), tower.tier]
	var commands := _commands_open()
	if tower.tier < _ui_config.max_tier:
		var cost := GridwardSim.upgrade_cost(
			tower.base_cost,
			tower.tier,
			_ui_config.upgrade_cost_factor,
			_ui_config.upgrade_cost_growth
		)
		_upgrade.text = "Upgrade %d" % cost
		_upgrade.disabled = not commands or _sim.get_gold() < cost
	else:
		_upgrade.text = "Upgrade"
		_upgrade.disabled = true
	_sell.text = "Sell"
	_sell.disabled = not commands
	_targeting.disabled = not commands
	var mode_index := TARGET_MODES.find(tower.targeting)
	if mode_index < 0:
		mode_index = 0
	_syncing_ui = true
	_targeting.select(mode_index)
	_syncing_ui = false


func _apply_styles() -> void:
	var card := Color(0.07, 0.1, 0.09, 0.92)
	_style_panel(_lives_gold, card)
	_style_panel(_wave_card, card)
	_style_panel(_tower_panel, Color(0.07, 0.1, 0.09, 0.96))
	_style_panel(_bottom_dock, Color(0.06, 0.09, 0.08, 0.94))
	_style_button(_speed, Color(0.18, 0.42, 0.34, 1), true)
	_style_button(_start, Color(0.18, 0.55, 0.38, 1), true)
	_style_button(_menu, Color(0.2, 0.24, 0.28, 1), false)
	_style_button(_upgrade, Color(0.45, 0.38, 0.16, 1), true)
	_style_button(_sell, Color(0.55, 0.24, 0.22, 1), false)


func _style_panel(panel: PanelContainer, color: Color) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(12)
	box.set_border_width_all(1)
	box.border_color = Color(1, 1, 1, 0.08)
	panel.add_theme_stylebox_override("panel", box)


func _style_button(btn: Button, color: Color, emphasize: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.set_corner_radius_all(10)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	if emphasize:
		normal.set_border_width_all(1)
		normal.border_color = Color(1, 1, 1, 0.18)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = color.lightened(0.12)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = color.lightened(0.18)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.15, 0.17, 0.2, 1)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", Color(0.95, 0.97, 1, 1))
	btn.add_theme_color_override("font_disabled_color", Color(0.45, 0.5, 0.55, 1))


func _event_is_play_key(event: InputEvent) -> bool:
	if event.is_action(&"gridward_start_wave") or event.is_action(&"gridward_speed"):
		return true
	if event.is_action(&"gridward_fit") or event.is_action(&"ui_cancel"):
		return true
	for action in TOWER_ACTIONS:
		if event.is_action(action):
			return true
	return false


func _begin_selected_match() -> void:
	var map_id := GridwardCatalog.MEADOW
	var difficulty := GridwardConfig.DIFF_NORMAL
	var host := _find_gridward_host()
	if host != null:
		var chosen_map = host.get("selected_map")
		var chosen_diff = host.get("selected_difficulty")
		if chosen_map != null:
			map_id = chosen_map
		if chosen_diff != null:
			difficulty = chosen_diff
	_difficulty = difficulty
	var config := GridwardConfig.for_difficulty(difficulty)
	_ui_config = config
	var built := GridwardCatalog.build_map(map_id)
	if built == null:
		built = GridwardCatalog.build_meadow()
	built.starting_gold = GridwardConfig.scaled_gold(built.starting_gold, config.difficulty_gold)
	_map = built
	_sim = GridwardSim.new(_map, GridwardCatalog.new(), 1)
	# Spawn HP reads difficulty_hp from the sim config. The sim builds a Normal
	# config itself; the campaign match replaces it before the first step.
	_sim._config = config


func _present_outcome() -> void:
	if _outcome_sent or _sim == null or _map == null:
		return
	var phase := _sim.get_phase()
	var won := phase == GridwardSim.Phase.VICTORY
	if not won and phase != GridwardSim.Phase.DEFEAT:
		return
	_outcome_sent = true
	var host := _find_gridward_host()
	if host != null and host.has_method("note_result"):
		host.call("note_result", _map.id, _difficulty, _sim.get_lives(), won)
	_submit(SceneRequest.replace(RESULTS_PATH))


func _find_gridward_host() -> Node:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("note_result") and node.has_method("choose_match"):
			return node
		node = node.get_parent()
	return null


func _submit(req: SceneRequest) -> void:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("submit"):
			node.call("submit", req)
			return
		node = node.get_parent()


static func _ensure_input_map() -> void:
	_bind_key(&"gridward_start_wave", KEY_SPACE)
	_bind_key(&"gridward_speed", KEY_TAB)
	_bind_key(&"gridward_fit", KEY_F)
	_bind_key(&"gridward_tower_1", KEY_1)
	_bind_key(&"gridward_tower_1", KEY_KP_1)
	_bind_key(&"gridward_tower_2", KEY_2)
	_bind_key(&"gridward_tower_2", KEY_KP_2)
	_bind_key(&"gridward_tower_3", KEY_3)
	_bind_key(&"gridward_tower_3", KEY_KP_3)
	_bind_key(&"gridward_tower_4", KEY_4)
	_bind_key(&"gridward_tower_4", KEY_KP_4)
	_bind_key(&"gridward_tower_5", KEY_5)
	_bind_key(&"gridward_tower_5", KEY_KP_5)


static func _bind_key(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for event in InputMap.action_get_events(action):
		var key := event as InputEventKey
		if key != null and key.physical_keycode == keycode:
			return
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)
