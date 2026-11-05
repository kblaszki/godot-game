class_name DistrictSim
extends RefCounted

const PHASE_ROLL := "roll"
const PHASE_BUY := "buy"
const PHASE_MANAGE := "manage"
const PHASE_AUCTION := "auction"
const PHASE_TOUR := "tour"
const PHASE_ARENA := "arena"
const PHASE_CHANCE := "chance"
const PHASE_OVER := "over"

var _config: DistrictConfig
var _rng: SeededRng
var _deck: ChanceDeck
var _players: Array[PlayerState] = []
var _owners: PackedInt32Array = PackedInt32Array()
var _builds: PackedInt32Array = PackedInt32Array()
var _phase: String = PHASE_ROLL
var _current: int = 0
var _doubles_streak: int = 0
var _pending_space: int = -1
var _winner: int = -1
var _extra_roll: bool = false
var _arena_pot: int = 0
var _parking_pot: int = 0
var _gadget_uses_left: PackedInt32Array = PackedInt32Array()
var _round: int = 0
var _auction_space: int = -1
var _auction_high_bid: int = 0
var _auction_high_bidder: int = -1
var _auction_passed: PackedInt32Array = PackedInt32Array()
var _pending_reroll: bool = false
var _trade: Dictionary = {}
var _turn_player: int = 0


func _init(config: DistrictConfig = null, rng: SeededRng = null) -> void:
	_config = config if config != null else DistrictConfig.new()
	_rng = rng if rng != null else SeededRng.new(1)
	_deck = ChanceDeck.new(_rng)


func setup(player_count: int, bot_mask: int = 0, seed_value: int = 1) -> void:
	_rng = SeededRng.new(seed_value)
	_deck = ChanceDeck.new(_rng)
	var count := clampi(player_count, _config.min_players, _config.max_players)
	_players.clear()
	_gadget_uses_left = PackedInt32Array()
	for i in count:
		var is_bot := (bot_mask & (1 << i)) != 0
		var p := PlayerState.new(_config.start_cash, is_bot)
		p.gadgets = GadgetRules.starter_kit()
		_players.append(p)
		_gadget_uses_left.append(_config.gadget_uses_per_match)
	_owners = PackedInt32Array()
	_builds = PackedInt32Array()
	_owners.resize(_config.space_count())
	_builds.resize(_config.space_count())
	for i in _owners.size():
		_owners[i] = -1
		_builds[i] = 0
	_phase = PHASE_ROLL
	_current = 0
	_turn_player = 0
	_doubles_streak = 0
	_pending_space = -1
	_winner = -1
	_extra_roll = false
	_arena_pot = 0
	_parking_pot = 0
	_round = 0
	_clear_auction()
	_trade.clear()
	_pending_reroll = false


func get_phase() -> String:
	return _phase


func get_current_player() -> int:
	return _current


func get_player_count() -> int:
	return _players.size()


func get_player(index: int) -> PlayerState:
	return _players[index]


func get_owner(space_index: int) -> int:
	if space_index < 0 or space_index >= _owners.size():
		return -1
	return _owners[space_index]


func get_build_level(space_index: int) -> int:
	if space_index < 0 or space_index >= _builds.size():
		return 0
	return _builds[space_index]


func get_pending_space() -> int:
	return _pending_space


func get_winner() -> int:
	return _winner


func get_config() -> DistrictConfig:
	return _config


func get_arena_pot() -> int:
	return _arena_pot


func get_gadget_uses_left(player_id: int) -> int:
	if player_id < 0 or player_id >= _gadget_uses_left.size():
		return 0
	return _gadget_uses_left[player_id]


func get_auction_space() -> int:
	return _auction_space


func get_auction_high_bid() -> int:
	return _auction_high_bid


func get_auction_high_bidder() -> int:
	return _auction_high_bidder


func has_monopoly(player_id: int, group: int) -> bool:
	var indices := _config.group_spaces(group)
	if indices.is_empty():
		return false
	for i in indices.size():
		var idx := indices[i]
		if _owners[idx] != player_id:
			return false
		if _players[player_id].bankrupt:
			return false
	return true


func current_rent(space_index: int) -> int:
	var space := _config.space_at(space_index)
	if space.kind != BoardSpace.KIND_PROPERTY:
		return 0
	var level := get_build_level(space_index)
	var amount := space.rent_at_level(level)
	var owner := _owners[space_index]
	if owner >= 0 and has_monopoly(owner, space.group) and level == 0:
		amount *= 2
	if owner >= 0 and _players[owner].double_rent_charges > 0:
		amount *= 2
	return amount


func roll() -> Array:
	var events: Array = []
	if _phase != PHASE_ROLL:
		return events
	var player := _players[_current]
	if player.bankrupt:
		_advance_turn(events)
		return events
	if player.frozen_turns > 0:
		player.frozen_turns -= 1
		events.append({"type": "frozen_skip", "player": _current, "left": player.frozen_turns})
		_advance_turn(events)
		return events
	if player.in_jail:
		return _roll_from_jail(events)

	var d1 := _rng.randi_range(1, 6)
	var d2 := _rng.randi_range(1, 6)
	var total := d1 + d2
	var doubles := d1 == d2
	events.append({"type": "rolled", "player": _current, "d1": d1, "d2": d2, "total": total, "doubles": doubles})

	var was_reroll := _pending_reroll
	if _pending_reroll:
		_pending_reroll = false
	elif doubles:
		_doubles_streak += 1
	else:
		_doubles_streak = 0

	if _doubles_streak >= 3:
		_send_to_jail(player, events)
		_doubles_streak = 0
		_extra_roll = false
		_advance_turn(events)
		return events

	_extra_roll = doubles and not was_reroll
	_move_player(player, total, events, true)
	_resolve_landing(player, events)
	return _after_resolve(events)


func buy() -> Array:
	var events: Array = []
	if _phase != PHASE_BUY or _pending_space < 0:
		return events
	var player := _players[_current]
	var space := _config.space_at(_pending_space)
	if space.kind != BoardSpace.KIND_PROPERTY or _owners[_pending_space] != -1:
		_pending_space = -1
		_finish_after_buy_window(events)
		return events
	if player.cash < space.price:
		_pending_space = -1
		_finish_after_buy_window(events)
		return events
	player.cash -= space.price
	_owners[_pending_space] = _current
	player.add_owned(_pending_space)
	_builds[_pending_space] = 0
	events.append({"type": "bought", "player": _current, "space": _pending_space, "price": space.price})
	_pending_space = -1
	_finish_after_buy_window(events)
	return events


func skip() -> Array:
	var events: Array = []
	if _phase != PHASE_BUY:
		return events
	var space_i := _pending_space
	events.append({"type": "skipped_buy", "player": _current, "space": space_i})
	_pending_space = -1
	if space_i >= 0 and _owners[space_i] == -1 and _config.space_at(space_i).kind == BoardSpace.KIND_PROPERTY:
		_start_auction(space_i, events)
		return events
	_finish_after_buy_window(events)
	return events


func build(space_index: int) -> Array:
	var events: Array = []
	if _phase != PHASE_MANAGE and _phase != PHASE_ROLL:
		return events
	var player := _players[_current]
	if player.bankrupt or not player.owns(space_index):
		return events
	var space := _config.space_at(space_index)
	if space.kind != BoardSpace.KIND_PROPERTY:
		return events
	if _config.require_monopoly_to_build and not has_monopoly(_current, space.group):
		return events
	var level := get_build_level(space_index)
	if level >= space.max_builds:
		return events
	if player.cash < space.build_cost:
		return events
	player.cash -= space.build_cost
	_builds[space_index] = level + 1
	player.set_build_level(space_index, level + 1)
	events.append({"type": "built", "player": _current, "space": space_index, "level": level + 1, "cost": space.build_cost})
	return events


func sell_build(space_index: int) -> Array:
	var events: Array = []
	if _phase != PHASE_MANAGE and _phase != PHASE_ROLL:
		return events
	var player := _players[_current]
	if not player.owns(space_index):
		return events
	var level := get_build_level(space_index)
	if level <= 0:
		return events
	var space := _config.space_at(space_index)
	var refund := space.build_cost / 2
	_builds[space_index] = level - 1
	player.set_build_level(space_index, level - 1)
	player.cash += refund
	events.append({"type": "sold_build", "player": _current, "space": space_index, "level": level - 1, "refund": refund})
	return events


func end_manage() -> Array:
	var events: Array = []
	if _phase != PHASE_MANAGE:
		return events
	if _extra_roll and not _players[_current].in_jail and not _players[_current].bankrupt:
		_phase = PHASE_ROLL
		return events
	_advance_turn(events)
	return events


func pick_tour_target(space_index: int) -> Array:
	var events: Array = []
	if _phase != PHASE_TOUR:
		return events
	if space_index < 0 or space_index >= _config.space_count():
		return events
	var player := _players[_current]
	var from := player.position
	player.position = space_index
	events.append({"type": "toured", "player": _current, "from": from, "to": space_index})
	_resolve_landing(player, events)
	return _after_resolve(events)


func resolve_arena() -> Array:
	var events: Array = []
	if _phase != PHASE_ARENA:
		return events
	var roll_v := _rng.randi_range(1, 6)
	events.append({"type": "arena_roll", "player": _current, "roll": roll_v, "pot": _arena_pot})
	if roll_v >= 4 and _arena_pot > 0:
		_players[_current].cash += _arena_pot
		events.append({"type": "arena_won", "player": _current, "amount": _arena_pot})
		_arena_pot = 0
	else:
		events.append({"type": "arena_miss", "player": _current, "pot": _arena_pot})
	_finish_after_buy_window(events)
	return events


func resolve_chance() -> Array:
	var events: Array = []
	if _phase != PHASE_CHANCE:
		return events
	var card := _deck.draw()
	events.append({"type": "chance_drawn", "player": _current, "card": card})
	_apply_chance(card, events)
	if _phase == PHASE_CHANCE:
		_finish_after_buy_window(events)
	return events


func auction_bid(amount: int) -> Array:
	var events: Array = []
	if _phase != PHASE_AUCTION or _auction_space < 0:
		return events
	var player := _players[_current]
	if player.bankrupt or amount <= _auction_high_bid or player.cash < amount:
		return events
	_auction_high_bid = amount
	_auction_high_bidder = _current
	_auction_passed = PackedInt32Array()
	events.append({"type": "auction_bid", "player": _current, "amount": amount, "space": _auction_space})
	_next_auction_seat(events)
	return events


func auction_pass() -> Array:
	var events: Array = []
	if _phase != PHASE_AUCTION:
		return events
	_auction_passed.append(_current)
	events.append({"type": "auction_pass", "player": _current})
	if _auction_all_others_passed():
		_finish_auction(events)
		return events
	_next_auction_seat(events)
	return events


func use_gadget(gadget_id: String, target: int = -1) -> Array:
	var events: Array = []
	if _phase != PHASE_ROLL and _phase != PHASE_MANAGE:
		return events
	var player := _players[_current]
	if _gadget_uses_left[_current] <= 0:
		return events
	if not player.consume_gadget(gadget_id):
		return events
	_gadget_uses_left[_current] -= 1
	events.append({"type": "gadget_used", "player": _current, "gadget": gadget_id, "target": target})
	match gadget_id:
		GadgetRules.SHIELD:
			player.shield_charges += 1
			events.append({"type": "buff_applied", "player": _current, "buff": "shield"})
		GadgetRules.DOUBLE_RENT:
			player.double_rent_charges += 1
			events.append({"type": "buff_applied", "player": _current, "buff": "double_rent"})
		GadgetRules.REROLL:
			_pending_reroll = true
			if _phase == PHASE_ROLL:
				return events + roll()
		GadgetRules.STEAL_CASH:
			var victim := target if target >= 0 and target < _players.size() else _next_alive_other(_current)
			if victim >= 0:
				var take := mini(_config.steal_cash_amount, _players[victim].cash)
				_players[victim].cash -= take
				player.cash += take
				events.append({"type": "cash_stolen", "from": victim, "to": _current, "amount": take})
		GadgetRules.FREEZE:
			var frozen := target if target >= 0 and target < _players.size() else _next_alive_other(_current)
			if frozen >= 0 and frozen != _current:
				_players[frozen].frozen_turns += 1
				events.append({"type": "buff_applied", "player": frozen, "buff": "freeze"})
	return events


func trade_offer(to_player: int, offer_cash: int, offer_spaces: PackedInt32Array, ask_cash: int, ask_spaces: PackedInt32Array) -> Array:
	var events: Array = []
	if _phase != PHASE_MANAGE:
		return events
	_trade = {
		"from": _current,
		"to": to_player,
		"offer_cash": offer_cash,
		"offer_spaces": offer_spaces,
		"ask_cash": ask_cash,
		"ask_spaces": ask_spaces,
	}
	events.append({"type": "trade_offered", "trade": _trade.duplicate(true)})
	return events


func trade_accept() -> Array:
	var events: Array = []
	if _trade.is_empty():
		return events
	var from_id := int(_trade.get("from", -1))
	var to_id := int(_trade.get("to", -1))
	if from_id < 0 or to_id < 0:
		return events
	var from_p := _players[from_id]
	var to_p := _players[to_id]
	var offer_cash := int(_trade.get("offer_cash", 0))
	var ask_cash := int(_trade.get("ask_cash", 0))
	if from_p.cash < offer_cash or to_p.cash < ask_cash:
		_trade.clear()
		return events
	from_p.cash -= offer_cash
	to_p.cash += offer_cash
	to_p.cash -= ask_cash
	from_p.cash += ask_cash
	for s in _trade.get("offer_spaces", PackedInt32Array()):
		_transfer_property(int(s), from_id, to_id)
	for s in _trade.get("ask_spaces", PackedInt32Array()):
		_transfer_property(int(s), to_id, from_id)
	events.append({"type": "trade_accepted", "trade": _trade.duplicate(true)})
	_trade.clear()
	return events


func trade_reject() -> Array:
	var events: Array = []
	if _trade.is_empty():
		return events
	events.append({"type": "trade_rejected", "trade": _trade.duplicate(true)})
	_trade.clear()
	return events


func bot_act() -> Array:
	if _phase == PHASE_OVER:
		return []
	var player := _players[_current]
	if player.bankrupt or not player.is_bot:
		return []
	match _phase:
		PHASE_ROLL:
			var gadget_id := DistrictBot.pick_gadget(self, _current)
			if gadget_id != "":
				return use_gadget(gadget_id)
			return roll()
		PHASE_BUY:
			if DistrictBot.should_buy(self, _current):
				return buy()
			return skip()
		PHASE_MANAGE:
			return _bot_manage()
		PHASE_AUCTION:
			return _bot_auction()
		PHASE_TOUR:
			return pick_tour_target(DistrictBot.pick_tour_target(self, _current))
		PHASE_ARENA:
			return resolve_arena()
		PHASE_CHANCE:
			return resolve_chance()
	return []


func _bot_manage() -> Array:
	var events: Array = []
	for i in _players[_current].owned.size():
		var space_i := _players[_current].owned[i]
		if DistrictBot.should_build(self, _current, space_i):
			var built := build(space_i)
			if not built.is_empty():
				events.append_array(built)
				break
	events.append_array(end_manage())
	return events


func _bot_auction() -> Array:
	var bid := DistrictBot.auction_bid_amount(self, _current)
	if bid > 0:
		return auction_bid(bid)
	return auction_pass()


func _after_resolve(events: Array) -> Array:
	if _phase == PHASE_BUY or _phase == PHASE_TOUR or _phase == PHASE_ARENA or _phase == PHASE_CHANCE or _phase == PHASE_AUCTION:
		return events
	if _phase == PHASE_OVER:
		return events
	if _phase == PHASE_MANAGE:
		return events
	if _extra_roll:
		_phase = PHASE_ROLL
		return events
	_advance_turn(events)
	return events


func _roll_from_jail(events: Array) -> Array:
	var player := _players[_current]
	var d1 := _rng.randi_range(1, 6)
	var d2 := _rng.randi_range(1, 6)
	var doubles := d1 == d2
	events.append({"type": "rolled", "player": _current, "d1": d1, "d2": d2, "total": d1 + d2, "doubles": doubles, "from_jail": true})
	player.jail_turns += 1
	if doubles or player.get_out_cards > 0:
		if not doubles and player.get_out_cards > 0:
			player.get_out_cards -= 1
			events.append({"type": "used_get_out", "player": _current})
		player.in_jail = false
		player.jail_turns = 0
		events.append({"type": "left_jail", "player": _current, "reason": "doubles" if doubles else "card"})
		_doubles_streak = 1 if doubles else 0
		_extra_roll = doubles
		_move_player(player, d1 + d2, events, true)
		_resolve_landing(player, events)
		return _after_resolve(events)
	if player.jail_turns >= _config.max_jail_turns:
		if player.cash < _config.jail_fine:
			_bankrupt_player(_current, -1, events)
			_advance_turn(events)
			return events
		player.cash -= _config.jail_fine
		player.in_jail = false
		player.jail_turns = 0
		events.append({"type": "left_jail", "player": _current, "reason": "fine", "amount": _config.jail_fine})
		_extra_roll = false
		_move_player(player, d1 + d2, events, true)
		_resolve_landing(player, events)
		return _after_resolve(events)
	_advance_turn(events)
	return events


func _move_player(player: PlayerState, steps: int, events: Array, grant_go: bool) -> void:
	var count := _config.space_count()
	var from := player.position
	var to := posmod(from + steps, count)
	if grant_go and steps > 0 and to < from:
		player.cash += _config.go_salary
		events.append({"type": "passed_go", "player": _current, "amount": _config.go_salary})
	player.position = to
	events.append({"type": "moved", "player": _current, "from": from, "to": to, "steps": steps})


func _resolve_landing(player: PlayerState, events: Array) -> void:
	var index := player.position
	var space := _config.space_at(index)
	match space.kind:
		BoardSpace.KIND_GO, BoardSpace.KIND_JAIL:
			_phase = PHASE_MANAGE if not _extra_roll else PHASE_ROLL
		BoardSpace.KIND_FREE:
			if _config.parking_collects_tax and _parking_pot > 0:
				player.cash += _parking_pot
				events.append({"type": "parking_collected", "player": _current, "amount": _parking_pot})
				_parking_pot = 0
			_phase = PHASE_MANAGE if not _extra_roll else PHASE_ROLL
		BoardSpace.KIND_TAX:
			var amount := space.tax
			if space.tax_percent > 0.0:
				amount = int(floor(float(player.cash) * space.tax_percent))
			_pay_tax(player, amount, events)
			_phase = PHASE_MANAGE if not _extra_roll else PHASE_ROLL
		BoardSpace.KIND_GOTO_JAIL:
			_send_to_jail(player, events)
			_extra_roll = false
			_phase = PHASE_ROLL
		BoardSpace.KIND_PROPERTY:
			var owner := _owners[index]
			if owner == -1:
				_phase = PHASE_BUY
				_pending_space = index
				events.append({"type": "offer_buy", "player": _current, "space": index, "price": space.price})
			elif owner != _current and not _players[owner].bankrupt:
				_pay_rent(player, owner, current_rent(index), index, events)
				_phase = PHASE_MANAGE if not _extra_roll else PHASE_ROLL
			else:
				_phase = PHASE_MANAGE if not _extra_roll else PHASE_ROLL
		BoardSpace.KIND_CHANCE:
			_phase = PHASE_CHANCE
			events.append({"type": "chance_pending", "player": _current})
		BoardSpace.KIND_TOUR:
			_phase = PHASE_TOUR
			events.append({"type": "tour_pending", "player": _current})
		BoardSpace.KIND_ARENA:
			var ante := mini(_config.arena_ante, player.cash)
			player.cash -= ante
			_arena_pot += ante
			events.append({"type": "arena_ante", "player": _current, "amount": ante, "pot": _arena_pot})
			_phase = PHASE_ARENA


func _apply_chance(card: Dictionary, events: Array) -> void:
	var player := _players[_current]
	var effect := str(card.get("effect", "noop"))
	match effect:
		"gain":
			var amt := int(card.get("amount", 0))
			player.cash += amt
			events.append({"type": "chance_gain", "player": _current, "amount": amt})
		"lose":
			_pay_tax(player, int(card.get("amount", 0)), events)
		"goto_go":
			player.position = 0
			player.cash += _config.go_salary
			events.append({"type": "passed_go", "player": _current, "amount": _config.go_salary})
			events.append({"type": "moved", "player": _current, "from": player.position, "to": 0, "steps": 0})
		"jail":
			_send_to_jail(player, events)
			_extra_roll = false
		"steal":
			var each := int(card.get("amount", 50))
			var total := 0
			for i in _players.size():
				if i == _current or _players[i].bankrupt:
					continue
				var take := mini(each, _players[i].cash)
				_players[i].cash -= take
				total += take
			player.cash += total
			events.append({"type": "chance_steal", "player": _current, "amount": total})
		"get_out":
			player.get_out_cards += 1
		"move":
			_move_player(player, int(card.get("steps", 0)), events, true)
			_resolve_landing(player, events)
			return
	if _phase == PHASE_CHANCE:
		_phase = PHASE_MANAGE if not _extra_roll else PHASE_ROLL


func _pay_tax(player: PlayerState, amount: int, events: Array) -> void:
	var paid := mini(player.cash, amount)
	player.cash -= paid
	if _config.parking_collects_tax:
		_parking_pot += paid
	events.append({"type": "taxed", "player": _current, "amount": paid})
	if player.cash <= 0 and paid < amount:
		_bankrupt_player(_current, -1, events)


func _pay_rent(payer: PlayerState, owner_id: int, rent: int, space_index: int, events: Array) -> void:
	if payer.shield_charges > 0:
		payer.shield_charges -= 1
		events.append({"type": "shield_blocked", "player": _current, "space": space_index})
		return
	var paid := mini(payer.cash, rent)
	payer.cash -= paid
	_players[owner_id].cash += paid
	if _players[owner_id].double_rent_charges > 0:
		_players[owner_id].double_rent_charges -= 1
		events.append({"type": "buff_expired", "player": owner_id, "buff": "double_rent"})
	events.append({"type": "paid_rent", "from": _current, "to": owner_id, "space": space_index, "amount": paid})
	if payer.cash <= 0 and paid < rent:
		_bankrupt_player(_current, owner_id, events)


func _send_to_jail(player: PlayerState, events: Array) -> void:
	player.position = _config.jail_index
	player.in_jail = true
	player.jail_turns = 0
	events.append({"type": "went_to_jail", "player": _current})


func _finish_after_buy_window(events: Array) -> void:
	if _phase == PHASE_OVER:
		return
	if _extra_roll and not _players[_current].in_jail and not _players[_current].bankrupt:
		_phase = PHASE_ROLL
		return
	_phase = PHASE_MANAGE


func _start_auction(space_index: int, events: Array) -> void:
	_auction_space = space_index
	_auction_high_bid = 0
	_auction_high_bidder = -1
	_auction_passed = PackedInt32Array()
	_turn_player = _current
	_phase = PHASE_AUCTION
	events.append({"type": "auction_started", "space": space_index})


func _clear_auction() -> void:
	_auction_space = -1
	_auction_high_bid = 0
	_auction_high_bidder = -1
	_auction_passed = PackedInt32Array()


func _auction_all_others_passed() -> bool:
	var need := 0
	for i in _players.size():
		if i != _auction_high_bidder and not _players[i].bankrupt:
			need += 1
	var passed_others := 0
	for i in _auction_passed.size():
		if _auction_passed[i] != _auction_high_bidder:
			passed_others += 1
	return passed_others >= need


func _next_auction_seat(events: Array) -> void:
	var start := _current
	for _i in _players.size():
		_current = (_current + 1) % _players.size()
		if not _players[_current].bankrupt:
			events.append({"type": "auction_turn", "player": _current})
			return
		if _current == start:
			break
	_finish_auction(events)


func _finish_auction(events: Array) -> void:
	if _auction_high_bidder >= 0 and _auction_high_bid > 0 and _auction_space >= 0:
		var winner := _players[_auction_high_bidder]
		var pay := mini(_auction_high_bid, winner.cash)
		winner.cash -= pay
		_owners[_auction_space] = _auction_high_bidder
		winner.add_owned(_auction_space)
		_builds[_auction_space] = 0
		events.append({"type": "auction_won", "player": _auction_high_bidder, "space": _auction_space, "price": pay})
	else:
		events.append({"type": "auction_failed", "space": _auction_space})
	_clear_auction()
	_current = _turn_player
	_finish_after_buy_window(events)


func _advance_turn(events: Array) -> void:
	if _phase == PHASE_OVER:
		return
	_doubles_streak = 0
	_extra_roll = false
	_pending_space = -1
	_pending_reroll = false
	_round += 1
	if _config.max_rounds > 0 and _round >= _config.max_rounds:
		_end_by_net_worth(events)
		return
	if _check_winner(events):
		return
	var start := _current
	for _i in _players.size():
		_current = (_current + 1) % _players.size()
		if not _players[_current].bankrupt:
			_phase = PHASE_ROLL
			events.append({"type": "turn_changed", "player": _current})
			return
		if _current == start:
			break
	_check_winner(events)


func _end_by_net_worth(events: Array) -> void:
	var best := -1
	var best_worth := -1
	for i in _players.size():
		if _players[i].bankrupt:
			continue
		var worth := _players[i].cash
		for j in _players[i].owned.size():
			var idx := _players[i].owned[j]
			worth += _config.space_at(idx).price + get_build_level(idx) * _config.space_at(idx).build_cost
		if worth > best_worth:
			best_worth = worth
			best = i
	_winner = best
	_phase = PHASE_OVER
	events.append({"type": "game_over", "winner": _winner, "reason": "rounds"})


func _bankrupt_player(player_id: int, creditor: int, events: Array) -> void:
	var player := _players[player_id]
	if player.bankrupt:
		return
	player.bankrupt = true
	player.cash = 0
	player.in_jail = false
	for i in player.owned.size():
		var space_index := player.owned[i]
		_builds[space_index] = 0
		if creditor >= 0 and not _players[creditor].bankrupt:
			_owners[space_index] = creditor
			_players[creditor].add_owned(space_index)
		else:
			_owners[space_index] = -1
	player.clear_owned()
	events.append({"type": "bankrupt", "player": player_id, "creditor": creditor})
	_extra_roll = false
	_check_winner(events)


func _check_winner(events: Array) -> bool:
	var alive := 0
	var last := -1
	for i in _players.size():
		if not _players[i].bankrupt:
			alive += 1
			last = i
	if alive <= 1 and _players.size() > 0:
		_winner = last
		_phase = PHASE_OVER
		events.append({"type": "game_over", "winner": _winner})
		return true
	return false


func _transfer_property(space_index: int, from_id: int, to_id: int) -> void:
	if space_index < 0 or space_index >= _owners.size():
		return
	if _owners[space_index] != from_id:
		return
	_players[from_id].remove_owned(space_index)
	_owners[space_index] = to_id
	_players[to_id].add_owned(space_index)
	_players[to_id].set_build_level(space_index, _builds[space_index])


func _next_alive_other(except_id: int) -> int:
	for i in _players.size():
		if i != except_id and not _players[i].bankrupt:
			return i
	return -1
