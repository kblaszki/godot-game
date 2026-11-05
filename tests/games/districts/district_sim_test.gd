extends "res://addons/gut/test.gd"


func test_default_board_should_have_thirty_two_spaces() -> void:
	var config := DistrictConfig.new()
	assert_eq(config.space_count(), 32)
	assert_eq(config.space_at(0).kind, BoardSpace.KIND_GO)
	assert_eq(config.space_at(config.jail_index).kind, BoardSpace.KIND_JAIL)
	assert_eq(config.space_at(config.tour_index).kind, BoardSpace.KIND_TOUR)
	assert_eq(config.space_at(config.arena_index).kind, BoardSpace.KIND_ARENA)


func test_same_seed_rolls_should_match() -> void:
	var left := _new_sim(2, 0, 11)
	var right := _new_sim(2, 0, 11)
	for _i in 80:
		assert_eq(_step_human(left), _step_human(right))
		if left.get_phase() == DistrictSim.PHASE_OVER:
			break
	assert_eq(left.get_phase(), right.get_phase())
	assert_eq(left.get_current_player(), right.get_current_player())
	assert_eq(left.get_player(0).cash, right.get_player(0).cash)
	assert_eq(left.get_player(0).position, right.get_player(0).position)


func test_buy_should_transfer_cash_and_owner() -> void:
	var sim := _new_sim(2, 0, 1)
	var space_index := _first_property_index(sim)
	var space := sim.get_config().space_at(space_index)
	sim.get_player(0).position = space_index
	sim._phase = DistrictSim.PHASE_BUY
	sim._pending_space = space_index
	var before := sim.get_player(0).cash
	var events := sim.buy()
	assert_true(_has_type(events, "bought"))
	assert_eq(sim.get_owner(space_index), 0)
	assert_eq(sim.get_player(0).cash, before - space.price)
	assert_true(sim.get_player(0).owns(space_index))
	assert_eq(sim.get_phase(), DistrictSim.PHASE_MANAGE)


func test_landing_on_owned_property_should_pay_rent() -> void:
	var sim := _new_sim(2, 0, 2)
	var space_index := _first_property_index(sim)
	var rent := sim.get_config().space_at(space_index).rent
	sim._owners[space_index] = 1
	sim.get_player(1).add_owned(space_index)
	var payer_before := sim.get_player(0).cash
	var owner_before := sim.get_player(1).cash
	sim.get_player(0).position = space_index
	var events: Array = []
	sim._resolve_landing(sim.get_player(0), events)
	assert_true(_has_type(events, "paid_rent"))
	assert_eq(sim.get_player(0).cash, payer_before - rent)
	assert_eq(sim.get_player(1).cash, owner_before + rent)


func test_monopoly_should_unlock_build_and_scale_rent() -> void:
	var sim := _new_sim(2, 0, 8)
	var group0 := sim.get_config().group_spaces(0)
	assert_gt(group0.size(), 1)
	for i in group0.size():
		var idx := group0[i]
		sim._owners[idx] = 0
		sim.get_player(0).add_owned(idx)
	assert_true(sim.has_monopoly(0, 0))
	sim._phase = DistrictSim.PHASE_MANAGE
	sim.get_player(0).cash = 5000
	var first := group0[0]
	var events := sim.build(first)
	assert_true(_has_type(events, "built"))
	assert_eq(sim.get_build_level(first), 1)
	var rent := sim.current_rent(first)
	assert_eq(rent, sim.get_config().space_at(first).rent_at_level(1))


func test_bankruptcy_should_clear_builds() -> void:
	var sim := _new_sim(2, 0, 9)
	var space_index := _first_property_index(sim)
	sim._owners[space_index] = 0
	sim.get_player(0).add_owned(space_index)
	sim._builds[space_index] = 2
	sim.get_player(0).set_build_level(space_index, 2)
	var events: Array = []
	sim._bankrupt_player(0, 1, events)
	assert_eq(sim.get_build_level(space_index), 0)
	assert_eq(sim.get_owner(space_index), 1)
	assert_true(_has_type(events, "bankrupt"))


func test_tour_should_teleport_without_go_salary() -> void:
	var sim := _new_sim(2, 0, 10)
	sim.get_player(0).position = sim.get_config().tour_index
	sim._phase = DistrictSim.PHASE_TOUR
	var before := sim.get_player(0).cash
	var target := _first_property_index(sim)
	var events := sim.pick_tour_target(target)
	assert_true(_has_type(events, "toured"))
	assert_eq(sim.get_player(0).position, target)
	assert_eq(sim.get_player(0).cash, before)
	assert_false(_has_type(events, "passed_go"))


func test_arena_should_grow_or_pay_pot() -> void:
	var sim := _new_sim(2, 0, 12)
	sim._phase = DistrictSim.PHASE_ARENA
	sim._arena_pot = 100
	sim._rng = _ForcedRollRng.new(5)
	var events := sim.resolve_arena()
	assert_true(_has_type(events, "arena_won"))
	assert_eq(sim.get_arena_pot(), 0)

	sim = _new_sim(2, 0, 13)
	sim._phase = DistrictSim.PHASE_ARENA
	sim._arena_pot = 80
	sim._rng = _ForcedRollRng.new(2)
	events = sim.resolve_arena()
	assert_true(_has_type(events, "arena_miss"))
	assert_eq(sim.get_arena_pot(), 80)


func test_tax_percent_should_scale_with_cash() -> void:
	var sim := _new_sim(2, 0, 14)
	var tax_index := -1
	for i in sim.get_config().space_count():
		var space := sim.get_config().space_at(i)
		if space.kind == BoardSpace.KIND_TAX and space.tax_percent > 0.0:
			tax_index = i
			break
	assert_gt(tax_index, -1)
	sim.get_player(0).cash = 1000
	sim.get_player(0).position = tax_index
	var events: Array = []
	sim._resolve_landing(sim.get_player(0), events)
	assert_true(_has_type(events, "taxed"))
	assert_eq(sim.get_player(0).cash, 900)


func test_skip_should_start_auction() -> void:
	var sim := _new_sim(2, 0, 15)
	var space_index := _first_property_index(sim)
	sim._phase = DistrictSim.PHASE_BUY
	sim._pending_space = space_index
	var events := sim.skip()
	assert_true(_has_type(events, "auction_started"))
	assert_eq(sim.get_phase(), DistrictSim.PHASE_AUCTION)
	assert_eq(sim.get_auction_space(), space_index)


func test_chance_deck_draw_should_emit_event() -> void:
	var sim := _new_sim(2, 0, 16)
	sim._phase = DistrictSim.PHASE_CHANCE
	var events := sim.resolve_chance()
	assert_true(_has_type(events, "chance_drawn"))


func test_shield_gadget_should_block_rent() -> void:
	var sim := _new_sim(2, 0, 17)
	var space_index := _first_property_index(sim)
	sim._owners[space_index] = 1
	sim.get_player(1).add_owned(space_index)
	sim.get_player(0).shield_charges = 1
	var before := sim.get_player(0).cash
	var events: Array = []
	sim._pay_rent(sim.get_player(0), 1, 50, space_index, events)
	assert_true(_has_type(events, "shield_blocked"))
	assert_eq(sim.get_player(0).cash, before)
	assert_eq(sim.get_player(0).shield_charges, 0)


func test_trade_should_swap_cash_and_city() -> void:
	var sim := _new_sim(2, 0, 18)
	var space_index := _first_property_index(sim)
	sim._owners[space_index] = 0
	sim.get_player(0).add_owned(space_index)
	sim._phase = DistrictSim.PHASE_MANAGE
	sim.trade_offer(1, 50, PackedInt32Array([space_index]), 0, PackedInt32Array())
	var events := sim.trade_accept()
	assert_true(_has_type(events, "trade_accepted"))
	assert_eq(sim.get_owner(space_index), 1)


func test_max_rounds_should_end_by_net_worth() -> void:
	var config := DistrictConfig.new()
	config.max_rounds = 1
	var sim := DistrictSim.new(config, SeededRng.new(19))
	sim.setup(2, 0, 19)
	sim.get_player(0).cash = 10
	sim.get_player(1).cash = 9999
	var events: Array = []
	sim._advance_turn(events)
	assert_true(_has_type(events, "game_over"))
	assert_eq(sim.get_winner(), 1)


func test_three_doubles_should_send_to_jail() -> void:
	var sim := _new_sim(2, 0, 3)
	sim._doubles_streak = 2
	sim._rng = _ForcedDoublesRng.new()
	var events := sim.roll()
	assert_true(_has_type(events, "went_to_jail"))
	assert_true(sim.get_player(0).in_jail)
	assert_eq(sim.get_player(0).position, sim.get_config().jail_index)


func test_bankruptcy_should_end_game_with_other_winner() -> void:
	var sim := _new_sim(2, 0, 4)
	sim.get_player(0).cash = 0
	var events: Array = []
	sim._bankrupt_player(0, 1, events)
	assert_true(_has_type(events, "bankrupt"))
	assert_true(_has_type(events, "game_over"))
	assert_eq(sim.get_winner(), 1)
	assert_eq(sim.get_phase(), DistrictSim.PHASE_OVER)


func test_bot_should_buy_when_cash_and_rent_ok() -> void:
	var sim := _new_sim(2, 1, 6)
	var space_index := _first_property_index(sim)
	var space := sim.get_config().space_at(space_index)
	sim.get_player(0).cash = space.price + DistrictBot.CASH_BUFFER + 10
	sim.get_player(0).position = space_index
	sim._phase = DistrictSim.PHASE_BUY
	sim._pending_space = space_index
	assert_true(DistrictBot.should_buy(sim, 0))
	var events := sim.bot_act()
	assert_true(_has_type(events, "bought"))
	assert_eq(sim.get_owner(space_index), 0)


func test_bot_should_skip_when_cash_too_low() -> void:
	var sim := _new_sim(2, 1, 7)
	var space_index := _first_property_index(sim)
	var space := sim.get_config().space_at(space_index)
	sim.get_player(0).cash = space.price + DistrictBot.CASH_BUFFER - 1
	sim._phase = DistrictSim.PHASE_BUY
	sim._pending_space = space_index
	assert_false(DistrictBot.should_buy(sim, 0))
	var events := sim.bot_act()
	assert_true(_has_type(events, "skipped_buy"))
	assert_true(_has_type(events, "auction_started"))


func test_bot_vs_bot_same_seed_should_match() -> void:
	var left := _new_sim(2, 3, 99)
	var right := _new_sim(2, 3, 99)
	for _i in 200:
		if left.get_phase() == DistrictSim.PHASE_OVER:
			break
		assert_eq(left.bot_act(), right.bot_act())
	assert_eq(left.get_phase(), right.get_phase())
	assert_eq(left.get_player(0).cash, right.get_player(0).cash)
	assert_eq(left.get_player(1).cash, right.get_player(1).cash)


func test_goto_jail_space_should_move_player() -> void:
	var sim := _new_sim(2, 0, 5)
	var goto_index := -1
	for i in sim.get_config().space_count():
		if sim.get_config().space_at(i).kind == BoardSpace.KIND_GOTO_JAIL:
			goto_index = i
			break
	assert_gt(goto_index, -1)
	sim.get_player(0).position = goto_index
	var events: Array = []
	sim._resolve_landing(sim.get_player(0), events)
	assert_true(_has_type(events, "went_to_jail"))
	assert_eq(sim.get_player(0).position, sim.get_config().jail_index)


func _step_human(sim: DistrictSim) -> Array:
	match sim.get_phase():
		DistrictSim.PHASE_ROLL:
			return sim.roll()
		DistrictSim.PHASE_BUY:
			return sim.skip()
		DistrictSim.PHASE_MANAGE:
			return sim.end_manage()
		DistrictSim.PHASE_AUCTION:
			return sim.auction_pass()
		DistrictSim.PHASE_TOUR:
			return sim.pick_tour_target(_first_property_index(sim))
		DistrictSim.PHASE_ARENA:
			return sim.resolve_arena()
		DistrictSim.PHASE_CHANCE:
			return sim.resolve_chance()
		_:
			return []


func _new_sim(players: int, bot_mask: int, seed_value: int) -> DistrictSim:
	var sim := DistrictSim.new(DistrictConfig.new(), SeededRng.new(seed_value))
	sim.setup(players, bot_mask, seed_value)
	return sim


func _first_property_index(sim: DistrictSim) -> int:
	for i in sim.get_config().space_count():
		if sim.get_config().space_at(i).kind == BoardSpace.KIND_PROPERTY:
			return i
	return -1


func _has_type(events: Array, type_name: String) -> bool:
	for event in events:
		if typeof(event) == TYPE_DICTIONARY and str(event.get("type", "")) == type_name:
			return true
	return false


class _ForcedDoublesRng extends SeededRng:
	func randi_range(_from: int, _to: int) -> int:
		return 4


class _ForcedRollRng extends SeededRng:
	var _value: int = 1

	func _init(value: int = 1) -> void:
		super._init(0)
		_value = value

	func randi_range(_from: int, _to: int) -> int:
		return _value
