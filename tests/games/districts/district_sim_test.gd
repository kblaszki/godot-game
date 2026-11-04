extends "res://addons/gut/test.gd"


func test_same_seed_rolls_should_match() -> void:
	var left := _new_sim(2, 0, 11)
	var right := _new_sim(2, 0, 11)
	for _i in 40:
		if left.get_phase() == DistrictSim.PHASE_BUY:
			assert_eq(left.skip(), right.skip())
		elif left.get_phase() == DistrictSim.PHASE_ROLL:
			assert_eq(left.roll(), right.roll())
		else:
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


func test_three_doubles_should_send_to_jail() -> void:
	var sim := _new_sim(2, 0, 3)
	sim._doubles_streak = 2
	# Force next roll to be doubles via monkeypatching rng draws is hard;
	# instead call send path directly after faking streak edge in roll with controlled rng.
	var forced := _ForcedDoublesRng.new()
	sim._rng = forced
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
	var sim := _new_sim(2, 1, 6) # seat 0 is bot
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
	assert_eq(sim.get_owner(space_index), -1)


func test_bot_vs_bot_same_seed_should_match() -> void:
	var left := _new_sim(2, 3, 99) # both bots
	var right := _new_sim(2, 3, 99)
	for _i in 80:
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
	func randi_range(from: int, to: int) -> int:
		return 4
