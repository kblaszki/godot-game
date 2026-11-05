extends Control

const SETUP_PATH := "res://games/districts/app/setup.tscn"
const PAUSE_PATH := "res://games/districts/app/pause_menu.tscn"
const STEP_SEC := 0.18

const GADGET_NAMES := {
	GadgetRules.SHIELD: "Shield",
	GadgetRules.DOUBLE_RENT: "x2 Rent",
	GadgetRules.REROLL: "Reroll",
	GadgetRules.STEAL_CASH: "Steal",
	GadgetRules.FREEZE: "Freeze",
}

var _sim: DistrictSim
var _cards: Array[PanelContainer] = []
var _card_styles: Array[StyleBoxFlat] = []
var _busy: bool = false
var _banner_shown: bool = false
var _pulse: float = 0.0
var _bot_cooldown: float = 0.35
var _chance_arm: float = -1.0
var _tour_ready: bool = false
var _build_key: String = ""
var _drag_last: Vector2 = Vector2.ZERO
var _orbiting: bool = false
var _panning: bool = false

@onready var _viewport: SubViewport = $BoardRoot/SubViewportContainer/SubViewport
@onready var _svc: SubViewportContainer = $BoardRoot/SubViewportContainer
@onready var _board: Board3D = $BoardRoot/SubViewportContainer/SubViewport/Board3D
@onready var _audio: DistrictAudio = $DistrictAudio
@onready var _feed: Label = $BottomBar/BarMargin/BarRow/Feed
@onready var _gadgets: HBoxContainer = $BottomBar/BarMargin/BarRow/Gadgets
@onready var _menu: Button = $BottomBar/BarMargin/BarRow/Menu
@onready var _dock: PanelContainer = $DockAnchor/ActionDock
@onready var _status: Label = $DockAnchor/ActionDock/Margin/Column/Status
@onready var _offer: Label = $DockAnchor/ActionDock/Margin/Column/Offer
@onready var _fit_btn: Button = $DockAnchor/ActionDock/Margin/Column/MainRow/Fit
@onready var _roll: Button = $DockAnchor/ActionDock/Margin/Column/MainRow/Roll
@onready var _buy: Button = $DockAnchor/ActionDock/Margin/Column/MainRow/Buy
@onready var _skip: Button = $DockAnchor/ActionDock/Margin/Column/MainRow/Skip
@onready var _done: Button = $DockAnchor/ActionDock/Margin/Column/MainRow/Done
@onready var _build_row: HBoxContainer = $DockAnchor/ActionDock/Margin/Column/BuildRow
@onready var _build_pick: OptionButton = $DockAnchor/ActionDock/Margin/Column/BuildRow/BuildPick
@onready var _build_btn: Button = $DockAnchor/ActionDock/Margin/Column/BuildRow/Build
@onready var _trade_row: HBoxContainer = $DockAnchor/ActionDock/Margin/Column/TradeRow
@onready var _trade_to: OptionButton = $DockAnchor/ActionDock/Margin/Column/TradeRow/TradeTo
@onready var _trade_city: OptionButton = $DockAnchor/ActionDock/Margin/Column/TradeRow/TradeCity
@onready var _trade_offer: Button = $DockAnchor/ActionDock/Margin/Column/TradeRow/TradeOffer
@onready var _trade_accept: Button = $DockAnchor/ActionDock/Margin/Column/TradeRow/TradeAccept
@onready var _tour_row: HBoxContainer = $DockAnchor/ActionDock/Margin/Column/TourRow
@onready var _tour_pick: OptionButton = $DockAnchor/ActionDock/Margin/Column/TourRow/TourPick
@onready var _tour_go: Button = $DockAnchor/ActionDock/Margin/Column/TourRow/TourGo
@onready var _extra_row: HBoxContainer = $DockAnchor/ActionDock/Margin/Column/ExtraRow
@onready var _arena_btn: Button = $DockAnchor/ActionDock/Margin/Column/ExtraRow/Arena
@onready var _chance_btn: Button = $DockAnchor/ActionDock/Margin/Column/ExtraRow/Chance
@onready var _auction_row: HBoxContainer = $DockAnchor/ActionDock/Margin/Column/AuctionRow
@onready var _bid: Button = $DockAnchor/ActionDock/Margin/Column/AuctionRow/Bid
@onready var _auction_pass: Button = $DockAnchor/ActionDock/Margin/Column/AuctionRow/AuctionPass
@onready var _roll_sum: Label = $RollSum
@onready var _dice_overlay: HBoxContainer = $DiceOverlay
@onready var _die_a: TextureRect = $DiceOverlay/DieA
@onready var _die_b: TextureRect = $DiceOverlay/DieB
@onready var _chance_card: PanelContainer = $ChanceCard
@onready var _chance_label: Label = $ChanceCard/ChanceLabel
@onready var _banner: PanelContainer = $Banner
@onready var _banner_label: Label = $Banner/BannerLabel


func _ready() -> void:
	var players := 2
	var bot_mask := 0
	var seed_value := 1
	var host := _find_host()
	if host != null:
		players = int(host.get("match_players"))
		bot_mask = int(host.get("match_bot_mask"))
		seed_value = int(host.get("match_seed"))
	var config := DistrictConfig.new()
	config.table_stake = _read_stake(host)
	config.apply_stake()
	_sim = DistrictSim.new(config, SeededRng.new(seed_value))
	_sim.setup(players, bot_mask, seed_value)
	if OS.has_feature("headless") or DisplayServer.get_name() == "headless":
		_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_bind_cards()
	_apply_styles()
	_connect_buttons()
	_build_gadget_buttons()
	_board.setup_match(_sim)
	_svc.gui_input.connect(_on_board_gui_input)
	_svc.resized.connect(_on_view_resized)
	_push_log("Table set. Claim the ring.")
	_refresh_hud()
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_board.fit(_view_size())


func _process(delta: float) -> void:
	if _sim == null:
		return
	_pulse += delta
	if not _busy:
		var shown := _sim.get_player(_sim.get_current_player())
		_board.highlight_space(shown.position, 0.5 + 0.5 * sin(_pulse * 3.5))
	if _busy or _sim.get_phase() == DistrictSim.PHASE_OVER:
		return
	var player := _sim.get_player(_sim.get_current_player())
	if player.is_bot and not player.bankrupt:
		_bot_cooldown -= delta
		if _bot_cooldown > 0.0:
			return
		_bot_cooldown = 0.4
		_run_action(func() -> Array: return _sim.bot_act())
		return
	if _sim.get_phase() == DistrictSim.PHASE_CHANCE and not player.is_bot:
		if _chance_arm < 0.0:
			_chance_arm = 0.35
		else:
			_chance_arm -= delta
			if _chance_arm <= 0.0:
				_chance_arm = -1.0
				_run_action(func() -> Array: return _sim.resolve_chance())
	elif _sim.get_phase() != DistrictSim.PHASE_CHANCE:
		_chance_arm = -1.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_submit(SceneRequest.push(PAUSE_PATH))
		get_viewport().set_input_as_handled()
	elif not _busy and _sim != null and _sim.get_phase() == DistrictSim.PHASE_OVER and event.is_action_pressed("ui_accept"):
		_submit(SceneRequest.replace(SETUP_PATH))
		get_viewport().set_input_as_handled()


func _bind_cards() -> void:
	_cards.clear()
	_cards.append($P0)
	_cards.append($P1)
	_cards.append($P2)
	_cards.append($P3)


func _connect_buttons() -> void:
	_menu.pressed.connect(_on_menu)
	_fit_btn.pressed.connect(_on_fit)
	_roll.pressed.connect(_on_roll)
	_buy.pressed.connect(_on_buy)
	_skip.pressed.connect(_on_skip)
	_done.pressed.connect(_on_done)
	_build_btn.pressed.connect(_on_build)
	_trade_offer.pressed.connect(_on_trade_offer)
	_trade_accept.pressed.connect(_on_trade_accept)
	_tour_go.pressed.connect(_on_tour)
	_arena_btn.pressed.connect(_on_arena)
	_chance_btn.pressed.connect(_on_chance)
	_bid.pressed.connect(_on_bid)
	_auction_pass.pressed.connect(_on_auction_pass)


func _build_gadget_buttons() -> void:
	for id in GadgetRules.ALL:
		var button := Button.new()
		button.text = str(GADGET_NAMES.get(id, id))
		button.set_meta("gadget_id", id)
		button.pressed.connect(_on_gadget.bind(id))
		button.custom_minimum_size = Vector2(0, 36)
		_style_button(button, Color(0.2, 0.24, 0.32, 1), false)
		_gadgets.add_child(button)


func _apply_styles() -> void:
	var dock := StyleBoxFlat.new()
	dock.bg_color = Color(0.07, 0.09, 0.13, 0.9)
	dock.set_corner_radius_all(14)
	dock.set_border_width_all(1)
	dock.border_color = Color(1, 1, 1, 0.08)
	dock.content_margin_left = 0
	dock.content_margin_right = 0
	dock.content_margin_top = 0
	dock.content_margin_bottom = 0
	_dock.add_theme_stylebox_override("panel", dock)

	var bar := dock.duplicate() as StyleBoxFlat
	bar.set_corner_radius_all(0)
	bar.bg_color = Color(0.06, 0.08, 0.11, 0.92)
	($BottomBar as PanelContainer).add_theme_stylebox_override("panel", bar)

	var banner := StyleBoxFlat.new()
	banner.bg_color = Color(0.07, 0.09, 0.12, 0.94)
	banner.set_border_width_all(2)
	banner.border_color = Color(1.0, 0.82, 0.35, 0.85)
	banner.set_corner_radius_all(16)
	banner.content_margin_left = 20
	banner.content_margin_right = 20
	banner.content_margin_top = 16
	banner.content_margin_bottom = 16
	_banner.add_theme_stylebox_override("panel", banner)

	var chance := StyleBoxFlat.new()
	chance.bg_color = Color(0.1, 0.14, 0.22, 0.96)
	chance.set_border_width_all(2)
	chance.border_color = Color(0.95, 0.82, 0.4, 0.9)
	chance.set_corner_radius_all(16)
	chance.content_margin_left = 18
	chance.content_margin_right = 18
	chance.content_margin_top = 16
	chance.content_margin_bottom = 16
	_chance_card.add_theme_stylebox_override("panel", chance)

	_roll_sum.add_theme_font_size_override("font_size", 72)
	_roll_sum.add_theme_color_override("font_color", Color(1, 0.96, 0.82, 1))
	_roll_sum.add_theme_constant_override("outline_size", 10)
	_roll_sum.add_theme_color_override("font_outline_color", Color(0.08, 0.12, 0.16, 0.85))

	for button in [_fit_btn, _skip, _auction_pass, _menu, _chance_btn]:
		_style_button(button, Color(0.2, 0.24, 0.3, 1), false)
	_style_button(_roll, Color(0.18, 0.55, 0.42, 1), true)
	_style_button(_buy, Color(0.55, 0.42, 0.15, 1), true)
	_style_button(_done, Color(0.18, 0.45, 0.62, 1), true)
	_style_button(_build_btn, Color(0.45, 0.32, 0.62, 1), true)
	_style_button(_trade_offer, Color(0.35, 0.4, 0.55, 1), true)
	_style_button(_trade_accept, Color(0.2, 0.5, 0.4, 1), true)
	_style_button(_tour_go, Color(0.2, 0.45, 0.62, 1), true)
	_style_button(_arena_btn, Color(0.62, 0.28, 0.24, 1), true)
	_style_button(_bid, Color(0.55, 0.42, 0.15, 1), true)

	_card_styles.clear()
	for card in _cards:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.1, 0.14, 0.9)
		style.set_corner_radius_all(12)
		style.content_margin_left = 10
		style.content_margin_right = 12
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		style.set_border_width_all(1)
		style.border_color = Color(1, 1, 1, 0.08)
		card.add_theme_stylebox_override("panel", style)
		_card_styles.append(style)


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
	pressed.bg_color = color.darkened(0.12)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.15, 0.17, 0.2, 1)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_color_override("font_color", Color(0.95, 0.97, 1, 1))
	btn.add_theme_color_override("font_disabled_color", Color(0.45, 0.5, 0.55, 1))


func _on_board_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_orbiting = mb.pressed
			_panning = false
			_drag_last = mb.position
			if mb.pressed:
				_board.begin_orbit()
			else:
				_board.end_orbit()
			_svc.accept_event()
		elif mb.button_index == MOUSE_BUTTON_MIDDLE or mb.button_index == MOUSE_BUTTON_RIGHT:
			_panning = mb.pressed
			_orbiting = false
			_drag_last = mb.position
			if mb.pressed:
				_board.begin_pan()
			else:
				_board.end_pan()
			_svc.accept_event()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_board.zoom_by(1.1)
			_svc.accept_event()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_board.zoom_by(1.0 / 1.1)
			_svc.accept_event()
	elif event is InputEventMouseMotion and (_orbiting or _panning):
		var mm := event as InputEventMouseMotion
		var delta := mm.position - _drag_last
		_drag_last = mm.position
		if _orbiting:
			_board.orbit_by(delta.x)
		elif _panning:
			_board.pan_by(delta, _view_size())
		_svc.accept_event()


func _on_view_resized() -> void:
	if _board != null:
		_board.fit(_view_size())


func _view_size() -> Vector2:
	var size := _svc.size
	if size.x < 2.0 or size.y < 2.0:
		return Vector2(1280, 720)
	return size


func _on_menu() -> void:
	_submit(SceneRequest.push(PAUSE_PATH))


func _on_fit() -> void:
	_board.fit(_view_size())


func _on_roll() -> void:
	if _busy or not _human_turn() or _sim.get_phase() != DistrictSim.PHASE_ROLL:
		return
	_run_action(func() -> Array: return _sim.roll())


func _on_buy() -> void:
	if _busy or not _human_turn() or _sim.get_phase() != DistrictSim.PHASE_BUY:
		return
	_run_action(func() -> Array: return _sim.buy())


func _on_skip() -> void:
	if _busy or not _human_turn() or _sim.get_phase() != DistrictSim.PHASE_BUY:
		return
	_run_action(func() -> Array: return _sim.skip())


func _on_done() -> void:
	if _busy or not _human_turn() or _sim.get_phase() != DistrictSim.PHASE_MANAGE:
		return
	_run_action(func() -> Array: return _sim.end_manage())


func _on_build() -> void:
	if _busy or not _human_turn() or _sim.get_phase() != DistrictSim.PHASE_MANAGE:
		return
	if _build_pick.item_count <= 0:
		_push_log("No district to build on.")
		return
	var space_i := int(_build_pick.get_item_metadata(_build_pick.selected))
	_run_action(func() -> Array: return _sim.build(space_i), "Can't build there.")


func _on_trade_offer() -> void:
	if _busy or not _human_turn() or _sim.get_phase() != DistrictSim.PHASE_MANAGE:
		return
	if _trade_to.item_count <= 0 or _trade_city.item_count <= 0:
		_push_log("Nothing to trade.")
		return
	var to_id := int(_trade_to.get_item_metadata(_trade_to.selected))
	var space_i := int(_trade_city.get_item_metadata(_trade_city.selected))
	_run_action(
		func() -> Array: return _sim.trade_offer(to_id, 0, PackedInt32Array([space_i]), 0, PackedInt32Array()),
		"Trade failed."
	)


func _on_trade_accept() -> void:
	if _busy or _sim.get_phase() != DistrictSim.PHASE_MANAGE:
		return
	_run_action(func() -> Array: return _sim.trade_accept(), "No open trade.")


func _on_tour() -> void:
	if _busy or not _human_turn() or _sim.get_phase() != DistrictSim.PHASE_TOUR:
		return
	if _tour_pick.item_count <= 0:
		return
	var space_i := int(_tour_pick.get_item_metadata(_tour_pick.selected))
	_run_action(func() -> Array: return _sim.pick_tour_target(space_i))


func _on_arena() -> void:
	if _busy or not _human_turn() or _sim.get_phase() != DistrictSim.PHASE_ARENA:
		return
	_run_action(func() -> Array: return _sim.resolve_arena())


func _on_chance() -> void:
	if _busy or not _human_turn() or _sim.get_phase() != DistrictSim.PHASE_CHANCE:
		return
	_chance_arm = -1.0
	_run_action(func() -> Array: return _sim.resolve_chance())


func _on_bid() -> void:
	if _busy or not _human_turn() or _sim.get_phase() != DistrictSim.PHASE_AUCTION:
		return
	var amount := maxi(_sim.get_auction_high_bid() + 10, 10)
	_run_action(func() -> Array: return _sim.auction_bid(amount), "Bid not accepted.")


func _on_auction_pass() -> void:
	if _busy or not _human_turn() or _sim.get_phase() != DistrictSim.PHASE_AUCTION:
		return
	_run_action(func() -> Array: return _sim.auction_pass())


func _on_gadget(gadget_id: String) -> void:
	if _busy or not _human_turn():
		return
	var phase := _sim.get_phase()
	if phase != DistrictSim.PHASE_ROLL and phase != DistrictSim.PHASE_MANAGE:
		return
	_run_action(func() -> Array: return _sim.use_gadget(gadget_id, -1), "Gadget unavailable.")


func _run_action(action: Callable, empty_note: String = "") -> void:
	if _busy:
		return
	_busy = true
	_refresh_hud()
	var events: Array = action.call()
	if events.is_empty() and empty_note != "":
		_push_log(empty_note)
	await _play_events(events)
	if not is_inside_tree():
		return
	_board.sync_from_sim(_sim)
	_board.layout_pawns(_sim)
	var seat := _sim.get_player(_sim.get_current_player())
	if not seat.bankrupt:
		_board.set_follow_space(seat.position)
	_busy = false
	_bot_cooldown = 0.25
	_refresh_hud()


func _play_events(events: Array) -> void:
	for item in events:
		if not is_inside_tree():
			return
		var data := item as Dictionary
		var type_name := str(data.get("type", ""))
		match type_name:
			"rolled":
				var d1 := int(data.get("d1", 1))
				var d2 := int(data.get("d2", 1))
				_push_log("%s rolled %d+%d" % [_seat(int(data.get("player", 0))), d1, d2])
				_cue("dice")
				_show_roll_sum(d1 + d2)
				await _animate_dice(d1, d2)
			"moved":
				var pid := int(data.get("player", 0))
				var to_i := int(data.get("to", 0))
				_push_log("%s → %s" % [_seat(pid), _space_name(to_i)])
				_cue("hop")
				await _animate_pawn_path(pid, int(data.get("from", 0)), to_i, int(data.get("steps", 1)))
			"passed_go":
				var amount := int(data.get("amount", 0))
				_push_log("%s +$%d Plaza" % [_seat(int(data.get("player", 0))), amount])
				_cue("cash")
				_toast_cash(int(data.get("player", 0)), amount)
			"offer_buy":
				_push_log("Offer %s ($%d)" % [_space_name(int(data.get("space", 0))), int(data.get("price", 0))])
			"bought":
				var space_i := int(data.get("space", 0))
				_push_log("%s bought %s" % [_seat(int(data.get("player", 0))), _space_name(space_i)])
				_cue("buy")
				_toast_cash(int(data.get("player", 0)), -int(data.get("price", 0)))
				await _board.pop_tile(space_i)
				_board.burst_at(space_i, Color(1.0, 0.85, 0.35, 1))
			"skipped_buy":
				_push_log("%s passed" % _seat(int(data.get("player", 0))))
			"paid_rent":
				var rent := int(data.get("amount", 0))
				_push_log("Rent $%d %s→%s" % [rent, _seat(int(data.get("from", 0))), _seat(int(data.get("to", 0)))])
				_cue("cash")
				_toast_cash(int(data.get("from", 0)), -rent)
				_toast_cash(int(data.get("to", 0)), rent)
			"built":
				var built_i := int(data.get("space", 0))
				var level := int(data.get("level", 1))
				var owner := int(data.get("player", 0))
				_push_log("%s built %s L%d" % [_seat(owner), _space_name(built_i), level])
				_cue("build")
				await _board.pop_building(built_i, level, _pawn_color(owner))
			"sold_build":
				var sold_i := int(data.get("space", 0))
				var seller := int(data.get("player", 0))
				_push_log("%s sold a floor on %s" % [_seat(seller), _space_name(sold_i)])
				_board.set_building(sold_i, int(data.get("level", 0)), _pawn_color(seller))
				_toast_cash(seller, int(data.get("refund", 0)))
			"taxed":
				var tax := int(data.get("amount", 0))
				_push_log("Tax $%d on %s" % [tax, _seat(int(data.get("player", 0)))])
				_cue("cash")
				_toast_cash(int(data.get("player", 0)), -tax)
			"went_to_jail":
				var jail_pid := int(data.get("player", 0))
				_push_log("%s → Holding" % _seat(jail_pid))
				_cue("shake")
				_board.snap_pawn(jail_pid, _sim.get_config().jail_index)
				_board.set_follow_space(_sim.get_config().jail_index)
				await _board.shake(0.85)
			"left_jail":
				_push_log("%s left Holding" % _seat(int(data.get("player", 0))))
			"chance_pending":
				_push_log("%s draws Chance" % _seat(int(data.get("player", 0))))
			"chance_drawn":
				var card := _as_dict(data.get("card", {}))
				_push_log(str(card.get("label", "Chance")))
				_cue("chance")
				await _show_chance(card)
			"chance_gain":
				var gain := int(data.get("amount", 0))
				_push_log("%s +$%d" % [_seat(int(data.get("player", 0))), gain])
				_cue("cash")
				_toast_cash(int(data.get("player", 0)), gain)
			"chance_steal":
				var stolen := int(data.get("amount", 0))
				_push_log("%s collected $%d" % [_seat(int(data.get("player", 0))), stolen])
				_toast_cash(int(data.get("player", 0)), stolen)
			"tour_pending":
				_push_log("%s — pick a district" % _seat(int(data.get("player", 0))))
			"toured":
				var tour_pid := int(data.get("player", 0))
				var dest := int(data.get("to", 0))
				_push_log("%s tours to %s" % [_seat(tour_pid), _space_name(dest)])
				_cue("hop")
				await _hop_pawn(tour_pid, dest)
			"arena_ante":
				var ante := int(data.get("amount", 0))
				_push_log("%s arena ante $%d" % [_seat(int(data.get("player", 0))), ante])
				_toast_cash(int(data.get("player", 0)), -ante)
			"arena_roll":
				var face := int(data.get("roll", 1))
				_push_log("%s arena die %d" % [_seat(int(data.get("player", 0))), face])
				_cue("dice")
				_show_roll_sum(face)
				await _animate_dice(face, face, false)
			"arena_won":
				var pot := int(data.get("amount", 0))
				_push_log("%s takes the pot $%d" % [_seat(int(data.get("player", 0))), pot])
				_cue("cash")
				_toast_cash(int(data.get("player", 0)), pot)
			"arena_miss":
				_push_log("%s misses the pot" % _seat(int(data.get("player", 0))))
			"auction_started":
				_push_log("Auction: %s" % _space_name(int(data.get("space", _sim.get_auction_space()))))
			"auction_turn":
				_push_log("Auction bid — %s" % _seat(int(data.get("player", 0))))
			"auction_bid":
				_push_log("%s bids $%d" % [_seat(int(data.get("player", 0))), int(data.get("amount", 0))])
			"auction_pass":
				_push_log("%s passes the auction" % _seat(int(data.get("player", 0))))
			"auction_won":
				var won_i := int(data.get("space", 0))
				_push_log("%s wins %s" % [_seat(int(data.get("player", 0))), _space_name(won_i)])
				_cue("buy")
				await _board.pop_tile(won_i)
			"auction_failed":
				_push_log("Auction failed")
			"gadget_used":
				_push_log("%s uses %s" % [_seat(int(data.get("player", 0))), str(data.get("gadget", "gadget"))])
			"buff_applied":
				_push_log("%s %s" % [_seat(int(data.get("player", 0))), str(data.get("buff", "buff"))])
			"buff_expired":
				_push_log("%s %s faded" % [_seat(int(data.get("player", 0))), str(data.get("buff", "buff"))])
			"shield_blocked":
				_push_log("%s shield blocks rent" % _seat(int(data.get("player", 0))))
			"cash_stolen":
				var take := int(data.get("amount", 0))
				_push_log("%s takes $%d from %s" % [_seat(int(data.get("to", 0))), take, _seat(int(data.get("from", 0)))])
				_toast_cash(int(data.get("from", 0)), -take)
				_toast_cash(int(data.get("to", 0)), take)
			"trade_offered":
				_push_log("Trade offered")
			"trade_accepted":
				_push_log("Trade accepted")
			"trade_rejected":
				_push_log("Trade rejected")
			"turn_changed":
				_push_log("Turn %s" % _seat(int(data.get("player", 0))))
			"bankrupt":
				_push_log("%s bankrupt" % _seat(int(data.get("player", 0))))
				_cue("shake")
				await _board.shake(1.15)
			"game_over":
				_push_log("Winner %s" % _seat(int(data.get("winner", 0))))
			"frozen_skip":
				_push_log("%s is frozen" % _seat(int(data.get("player", 0))))
			"parking_collected":
				var parked := int(data.get("amount", 0))
				_push_log("%s collects $%d" % [_seat(int(data.get("player", 0))), parked])
				_toast_cash(int(data.get("player", 0)), parked)
			"used_get_out":
				_push_log("%s uses a release card" % _seat(int(data.get("player", 0))))
			_:
				if type_name != "":
					_push_log(type_name)
		if is_inside_tree():
			_refresh_hud()


func _animate_dice(d1: int, d2: int, pair: bool = true) -> void:
	_die_a.texture = load("res://games/districts/assets/kenney_boardgame/dice/die_%d.png" % clampi(d1, 1, 6))
	_die_b.visible = pair
	if pair:
		_die_b.texture = load("res://games/districts/assets/kenney_boardgame/dice/die_%d.png" % clampi(d2, 1, 6))
	_dice_overlay.visible = true
	_dice_overlay.pivot_offset = _dice_overlay.size * 0.5
	if _dice_overlay.pivot_offset == Vector2.ZERO:
		_dice_overlay.pivot_offset = Vector2(72, 32)
	_dice_overlay.modulate.a = 0.0
	_dice_overlay.scale = Vector2(0.6, 0.6)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_dice_overlay, "modulate:a", 1.0, 0.1)
	tw.tween_property(_dice_overlay, "scale", Vector2(1.12, 1.12), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	if not is_inside_tree():
		return
	var settle := create_tween()
	settle.tween_property(_dice_overlay, "scale", Vector2.ONE, 0.08)
	await settle.finished
	if not is_inside_tree():
		return
	await get_tree().create_timer(0.42).timeout
	if not is_inside_tree():
		return
	var fade := create_tween()
	fade.tween_property(_dice_overlay, "modulate:a", 0.0, 0.16)
	await fade.finished
	if not is_inside_tree():
		return
	_dice_overlay.visible = false
	_dice_overlay.modulate.a = 1.0
	_dice_overlay.scale = Vector2.ONE


func _show_roll_sum(total: int) -> void:
	_roll_sum.text = str(total)
	_roll_sum.visible = true
	_roll_sum.pivot_offset = _roll_sum.size * 0.5
	if _roll_sum.pivot_offset == Vector2.ZERO:
		_roll_sum.pivot_offset = Vector2(70, 48)
	_roll_sum.modulate.a = 0.0
	_roll_sum.scale = Vector2(0.55, 0.55)
	var tw := create_tween()
	tw.tween_property(_roll_sum, "modulate:a", 1.0, 0.1)
	tw.parallel().tween_property(_roll_sum, "scale", Vector2(1.15, 1.15), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_roll_sum, "scale", Vector2.ONE, 0.08)
	tw.tween_interval(0.55)
	tw.tween_property(_roll_sum, "modulate:a", 0.0, 0.22)
	tw.tween_callback(func() -> void:
		if is_instance_valid(_roll_sum):
			_roll_sum.visible = false
			_roll_sum.modulate.a = 1.0
	)


func _animate_pawn_path(player_id: int, from_i: int, to_i: int, steps: int) -> void:
	var pawn := _board.pawn_node(player_id)
	if pawn == null:
		return
	if steps == 0:
		_board.snap_pawn(player_id, to_i)
		_board.set_follow_space(to_i)
		_board.flash_tile(to_i)
		return
	var count := _sim.get_config().space_count()
	var cur := from_i
	var dir := 1 if steps > 0 else -1
	for _step in absi(steps):
		cur = posmod(cur + dir, count)
		var target := _board.pawn_local(player_id, cur)
		_board.set_follow_space(cur)
		var hop := create_tween()
		hop.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		hop.tween_property(pawn, "position", target + Vector3(0, 18, 0), STEP_SEC * 0.45)
		hop.tween_property(pawn, "position", target, STEP_SEC * 0.55)
		await hop.finished
		if not is_inside_tree():
			return
		_board.flash_tile(cur)
	_board.snap_pawn(player_id, to_i)
	_board.set_follow_space(to_i)


func _hop_pawn(player_id: int, space_i: int) -> void:
	var pawn := _board.pawn_node(player_id)
	if pawn == null:
		return
	var target := _board.pawn_local(player_id, space_i)
	_board.set_follow_space(space_i)
	var peak := (pawn.position + target) * 0.5 + Vector3(0, 42, 0)
	var hop := create_tween()
	hop.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	hop.tween_property(pawn, "position", peak, 0.2)
	hop.tween_property(pawn, "position", target, 0.2)
	await hop.finished
	if is_inside_tree():
		_board.flash_tile(space_i)


func _show_chance(card: Dictionary) -> void:
	_chance_label.text = str(card.get("label", "Chance"))
	_chance_card.visible = true
	_chance_card.modulate.a = 1.0
	_chance_card.pivot_offset = _chance_card.size * 0.5
	if _chance_card.pivot_offset == Vector2.ZERO:
		_chance_card.pivot_offset = Vector2(180, 48)
	_chance_card.scale = Vector2(0.06, 1.0)
	_chance_card.rotation_degrees = -16.0
	var tw := create_tween()
	tw.tween_property(_chance_card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_chance_card, "rotation_degrees", 0.0, 0.22)
	await tw.finished
	if not is_inside_tree():
		return
	await get_tree().create_timer(0.55).timeout
	if not is_inside_tree():
		return
	var out := create_tween()
	out.tween_property(_chance_card, "scale:x", 0.06, 0.14)
	out.parallel().tween_property(_chance_card, "modulate:a", 0.0, 0.14)
	await out.finished
	if not is_inside_tree():
		return
	_chance_card.visible = false
	_chance_card.scale = Vector2.ONE
	_chance_card.modulate.a = 1.0
	_chance_card.rotation_degrees = 0.0


func _toast_cash(player_id: int, delta_cash: int) -> void:
	if delta_cash == 0 or player_id < 0 or player_id >= _cards.size():
		return
	var label := Label.new()
	label.text = "%+d" % delta_cash
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override(
		"font_color",
		Color(0.45, 0.95, 0.65, 1) if delta_cash > 0 else Color(1.0, 0.45, 0.4, 1)
	)
	label.position = Vector2(28, 8)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cards[player_id].add_child(label)
	var tw := create_tween()
	tw.tween_property(label, "position:y", label.position.y - 36.0, 0.7)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 0.7)
	tw.tween_callback(label.queue_free)


func _push_log(line: String) -> void:
	_feed.text = line


func _cue(cue: String) -> void:
	if _audio != null:
		_audio.play_cue(cue)


func _refresh_hud() -> void:
	var count := _sim.get_player_count()
	var current := _sim.get_current_player()
	var bots := _bot_count()
	for i in _cards.size():
		var card := _cards[i]
		card.visible = i < count
		if i >= count:
			continue
		var player := _sim.get_player(i)
		var nick := "P%d" % (i + 1)
		if player.is_bot:
			nick = "Bot" if bots <= 1 else "Bot %d" % (i + 1)
		var nick_label := card.get_node("Row/Text/Nick") as Label
		var cash_label := card.get_node("Row/Text/Cash") as Label
		var avatar := card.get_node("Row/Avatar") as ColorRect
		nick_label.text = nick
		var extra := ""
		if player.bankrupt:
			extra = " · out"
		elif player.in_jail:
			extra = " · island"
		cash_label.text = "$%d%s" % [player.cash, extra]
		avatar.color = _pawn_color(i)
		card.modulate = Color(1, 1, 1, 0.5) if player.bankrupt else Color.WHITE
		var style := _card_styles[i]
		style.set_border_width_all(2 if i == current and not player.bankrupt else 1)
		style.border_color = _pawn_color(i) if i == current else Color(1, 1, 1, 0.08)

	var phase := _sim.get_phase()
	var human := _human_turn()
	_status.text = "%s · %s" % [_seat(current), phase.to_upper()]
	_offer.text = _offer_text(phase)
	_offer.visible = _offer.text != ""
	_sync_build_list(phase)
	_sync_tour_list(phase)
	_sync_gadgets(phase, human)
	if phase == DistrictSim.PHASE_AUCTION:
		var next_bid := maxi(_sim.get_auction_high_bid() + 10, 10)
		_bid.text = "Bid $%d" % next_bid
	_roll.visible = phase == DistrictSim.PHASE_ROLL
	_buy.visible = phase == DistrictSim.PHASE_BUY
	_skip.visible = phase == DistrictSim.PHASE_BUY
	_done.visible = phase == DistrictSim.PHASE_MANAGE
	_build_row.visible = phase == DistrictSim.PHASE_MANAGE and human
	_trade_row.visible = phase == DistrictSim.PHASE_MANAGE and human
	_sync_trade_list(phase)
	_tour_row.visible = phase == DistrictSim.PHASE_TOUR and human
	_arena_btn.visible = phase == DistrictSim.PHASE_ARENA
	_chance_btn.visible = phase == DistrictSim.PHASE_CHANCE
	_extra_row.visible = _arena_btn.visible or _chance_btn.visible
	_auction_row.visible = phase == DistrictSim.PHASE_AUCTION and human
	var unlocked := not _busy and human
	_fit_btn.disabled = false
	_roll.disabled = not (unlocked and phase == DistrictSim.PHASE_ROLL)
	_buy.disabled = not (unlocked and phase == DistrictSim.PHASE_BUY)
	_skip.disabled = not (unlocked and phase == DistrictSim.PHASE_BUY)
	_done.disabled = not (unlocked and phase == DistrictSim.PHASE_MANAGE)
	_build_btn.disabled = not (unlocked and phase == DistrictSim.PHASE_MANAGE and _build_pick.item_count > 0)
	_trade_offer.disabled = not (unlocked and phase == DistrictSim.PHASE_MANAGE and _trade_city.item_count > 0 and _trade_to.item_count > 0)
	var pending_trade := _sim.get_pending_trade()
	var can_accept := not pending_trade.is_empty() and int(pending_trade.get("to", -1)) == current
	_trade_accept.disabled = not (not _busy and phase == DistrictSim.PHASE_MANAGE and can_accept)
	_tour_go.disabled = not (unlocked and phase == DistrictSim.PHASE_TOUR)
	_arena_btn.disabled = not (unlocked and phase == DistrictSim.PHASE_ARENA)
	_chance_btn.disabled = not (unlocked and phase == DistrictSim.PHASE_CHANCE)
	_auction_pass.disabled = not (unlocked and phase == DistrictSim.PHASE_AUCTION)
	var bid_amount := maxi(_sim.get_auction_high_bid() + 10, 10)
	var can_bid := _sim.get_player(current).cash >= bid_amount
	_bid.disabled = not (unlocked and phase == DistrictSim.PHASE_AUCTION and can_bid)
	if phase == DistrictSim.PHASE_OVER:
		_banner.visible = true
		var winner := _sim.get_winner()
		_banner_label.text = "%s holds the districts\nEnter — new match" % _seat(winner)
		if not _banner_shown:
			_banner_shown = true
			_banner.pivot_offset = _banner.size * 0.5
			_banner.scale = Vector2(0.86, 0.86)
			_banner.modulate.a = 0.0
			var tw := create_tween().set_parallel(true)
			tw.tween_property(_banner, "modulate:a", 1.0, 0.2)
			tw.tween_property(_banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_banner.visible = false
		_banner_shown = false


func _offer_text(phase: String) -> String:
	if phase == DistrictSim.PHASE_BUY and _sim.get_pending_space() >= 0:
		var space := _sim.get_config().space_at(_sim.get_pending_space())
		return "Buy %s for $%d?" % [space.name, space.price]
	if phase == DistrictSim.PHASE_AUCTION and _sim.get_auction_space() >= 0:
		var space := _sim.get_config().space_at(_sim.get_auction_space())
		var high := _sim.get_auction_high_bid()
		var who := ""
		if _sim.get_auction_high_bidder() >= 0:
			who = " · %s" % _seat(_sim.get_auction_high_bidder())
		return "Auction %s · $%d%s" % [space.name, high, who]
	if phase == DistrictSim.PHASE_TOUR:
		return "World Tour — choose a space"
	if phase == DistrictSim.PHASE_ARENA:
		return "Arena pot $%d — 4+ wins" % _sim.get_arena_pot()
	if phase == DistrictSim.PHASE_CHANCE:
		return "Chance"
	if phase == DistrictSim.PHASE_MANAGE:
		return "Manage districts, then Done"
	return ""


func _sync_build_list(phase: String) -> void:
	if phase != DistrictSim.PHASE_MANAGE:
		_build_key = ""
		return
	var player := _sim.get_player(_sim.get_current_player())
	var key := ""
	for i in player.owned.size():
		var space_i := player.owned[i]
		key += "%d:%d," % [space_i, _sim.get_build_level(space_i)]
	if key == _build_key:
		return
	_build_key = key
	_build_pick.clear()
	var select_at := 0
	for i in player.owned.size():
		var space_i := player.owned[i]
		var space := _sim.get_config().space_at(space_i)
		_build_pick.add_item("%s L%d" % [space.name, _sim.get_build_level(space_i)])
		_build_pick.set_item_metadata(_build_pick.item_count - 1, space_i)
		if space_i == player.position:
			select_at = _build_pick.item_count - 1
	if _build_pick.item_count > 0:
		_build_pick.select(select_at)


func _sync_tour_list(phase: String) -> void:
	if phase != DistrictSim.PHASE_TOUR:
		_tour_ready = false
		return
	if _tour_ready:
		return
	_tour_pick.clear()
	var config := _sim.get_config()
	for i in config.space_count():
		_tour_pick.add_item(config.space_at(i).name)
		_tour_pick.set_item_metadata(i, i)
	_tour_ready = true


func _sync_trade_list(phase: String) -> void:
	if phase != DistrictSim.PHASE_MANAGE:
		return
	var current := _sim.get_current_player()
	var player := _sim.get_player(current)
	_trade_to.clear()
	for i in _sim.get_player_count():
		if i == current or _sim.get_player(i).bankrupt:
			continue
		_trade_to.add_item(_seat(i))
		_trade_to.set_item_metadata(_trade_to.item_count - 1, i)
	_trade_city.clear()
	for i in player.owned.size():
		var space_i := player.owned[i]
		_trade_city.add_item(_sim.get_config().space_at(space_i).name)
		_trade_city.set_item_metadata(_trade_city.item_count - 1, space_i)


func _sync_gadgets(phase: String, human: bool) -> void:
	var player := _sim.get_player(_sim.get_current_player())
	var usable := human and not _busy and (phase == DistrictSim.PHASE_ROLL or phase == DistrictSim.PHASE_MANAGE)
	usable = usable and _sim.get_gadget_uses_left(_sim.get_current_player()) > 0
	for button in _gadgets.get_children():
		var gadget_id := str(button.get_meta("gadget_id"))
		var count := int(player.gadgets.get(gadget_id, 0))
		var gadget_button := button as Button
		if gadget_button == null:
			continue
		gadget_button.text = "%s %d" % [str(GADGET_NAMES.get(gadget_id, gadget_id)), count]
		gadget_button.visible = true
		gadget_button.disabled = not (usable and count > 0)


func _bot_count() -> int:
	var n := 0
	for i in _sim.get_player_count():
		if _sim.get_player(i).is_bot:
			n += 1
	return n


func _human_turn() -> bool:
	var player := _sim.get_player(_sim.get_current_player())
	return not player.is_bot and not player.bankrupt


func _seat(player_id: int) -> String:
	if player_id < 0 or player_id >= _sim.get_player_count():
		return "P?"
	if _sim.get_player(player_id).is_bot:
		return "Bot" if _bot_count() <= 1 else "Bot %d" % (player_id + 1)
	return "P%d" % (player_id + 1)


func _space_name(index: int) -> String:
	if index < 0 or index >= _sim.get_config().space_count():
		return "space"
	return _sim.get_config().space_at(index).name


func _pawn_color(player_id: int) -> Color:
	return Board3D.PAWN_COLORS[player_id % Board3D.PAWN_COLORS.size()]


func _as_dict(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}


func _read_stake(host: Node) -> int:
	if host == null:
		return 1
	if "match_table_stake" in host:
		return maxi(int(host.get("match_table_stake")), 1)
	if host.has_meta("table_stake"):
		return maxi(int(host.get_meta("table_stake")), 1)
	return 1


func _find_host() -> Node:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("configure_match"):
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
