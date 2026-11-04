class_name DistrictSim
extends RefCounted

const PHASE_ROLL := "roll"
const PHASE_BUY := "buy"
const PHASE_OVER := "over"

var _config: DistrictConfig
var _rng: SeededRng
var _players: Array[PlayerState] = []
var _owners: PackedInt32Array = PackedInt32Array()
var _phase: String = PHASE_ROLL
var _current: int = 0
var _doubles_streak: int = 0
var _pending_space: int = -1
var _winner: int = -1
var _extra_roll: bool = false


func _init(config: DistrictConfig = null, rng: SeededRng = null) -> void:
	_config = config if config != null else DistrictConfig.new()
	_rng = rng if rng != null else SeededRng.new(1)


func setup(player_count: int, bot_mask: int = 0, seed_value: int = 1) -> void:
	_rng = SeededRng.new(seed_value)
	var count := clampi(player_count, _config.min_players, _config.max_players)
	_players.clear()
	for i in count:
		var is_bot := (bot_mask & (1 << i)) != 0
		_players.append(PlayerState.new(_config.start_cash, is_bot))
	_owners = PackedInt32Array()
	_owners.resize(_config.space_count())
	for i in _owners.size():
		_owners[i] = -1
	_phase = PHASE_ROLL
	_current = 0
	_doubles_streak = 0
	_pending_space = -1
	_winner = -1
	_extra_roll = false


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


func get_pending_space() -> int:
	return _pending_space


func get_winner() -> int:
	return _winner


func get_config() -> DistrictConfig:
	return _config


func roll() -> Array:
	var events: Array = []
	if _phase != PHASE_ROLL:
		return events
	var player := _players[_current]
	if player.bankrupt:
		_advance_turn(events)
		return events

	if player.in_jail:
		return _roll_from_jail(events)

	var d1 := _rng.randi_range(1, 6)
	var d2 := _rng.randi_range(1, 6)
	var total := d1 + d2
	var doubles := d1 == d2
	events.append({"type": "rolled", "player": _current, "d1": d1, "d2": d2, "total": total, "doubles": doubles})

	if doubles:
		_doubles_streak += 1
	else:
		_doubles_streak = 0

	if _doubles_streak >= 3:
		_send_to_jail(player, events)
		_doubles_streak = 0
		_extra_roll = false
		_advance_turn(events)
		return events

	_extra_roll = doubles
	_move_player(player, total, events)
	_resolve_landing(player, events)
	if _phase == PHASE_BUY:
		return events
	if _phase == PHASE_OVER:
		return events
	if _extra_roll:
		_phase = PHASE_ROLL
		return events
	_advance_turn(events)
	return events


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
	events.append({"type": "bought", "player": _current, "space": _pending_space, "price": space.price})
	_pending_space = -1
	_finish_after_buy_window(events)
	return events


func skip() -> Array:
	var events: Array = []
	if _phase != PHASE_BUY:
		return events
	events.append({"type": "skipped_buy", "player": _current, "space": _pending_space})
	_pending_space = -1
	_finish_after_buy_window(events)
	return events


func _roll_from_jail(events: Array) -> Array:
	var player := _players[_current]
	var d1 := _rng.randi_range(1, 6)
	var d2 := _rng.randi_range(1, 6)
	var doubles := d1 == d2
	events.append({"type": "rolled", "player": _current, "d1": d1, "d2": d2, "total": d1 + d2, "doubles": doubles, "from_jail": true})
	player.jail_turns += 1
	if doubles:
		player.in_jail = false
		player.jail_turns = 0
		events.append({"type": "left_jail", "player": _current, "reason": "doubles"})
		_doubles_streak = 1
		_extra_roll = true
		_move_player(player, d1 + d2, events)
		_resolve_landing(player, events)
		if _phase == PHASE_BUY or _phase == PHASE_OVER:
			return events
		_phase = PHASE_ROLL
		return events
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
		_move_player(player, d1 + d2, events)
		_resolve_landing(player, events)
		if _phase == PHASE_BUY or _phase == PHASE_OVER:
			return events
		_advance_turn(events)
		return events
	_advance_turn(events)
	return events


func _move_player(player: PlayerState, steps: int, events: Array) -> void:
	var count := _config.space_count()
	var from := player.position
	var to := (from + steps) % count
	if to < from:
		player.cash += _config.go_salary
		events.append({"type": "passed_go", "player": _current, "amount": _config.go_salary})
	player.position = to
	events.append({"type": "moved", "player": _current, "from": from, "to": to, "steps": steps})


func _resolve_landing(player: PlayerState, events: Array) -> void:
	var index := player.position
	var space := _config.space_at(index)
	match space.kind:
		BoardSpace.KIND_GO:
			pass
		BoardSpace.KIND_FREE, BoardSpace.KIND_JAIL:
			pass
		BoardSpace.KIND_TAX:
			_pay_tax(player, space.tax, events)
		BoardSpace.KIND_GOTO_JAIL:
			_send_to_jail(player, events)
			_extra_roll = false
		BoardSpace.KIND_PROPERTY:
			var owner := _owners[index]
			if owner == -1:
				_phase = PHASE_BUY
				_pending_space = index
				events.append({"type": "offer_buy", "player": _current, "space": index, "price": space.price})
			elif owner != _current and not _players[owner].bankrupt:
				_pay_rent(player, owner, space.rent, index, events)


func _pay_tax(player: PlayerState, amount: int, events: Array) -> void:
	var paid := mini(player.cash, amount)
	player.cash -= paid
	events.append({"type": "taxed", "player": _current, "amount": paid})
	if player.cash <= 0 and paid < amount:
		_bankrupt_player(_current, -1, events)


func _pay_rent(payer: PlayerState, owner_id: int, rent: int, space_index: int, events: Array) -> void:
	var paid := mini(payer.cash, rent)
	payer.cash -= paid
	_players[owner_id].cash += paid
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
	_advance_turn(events)


func _advance_turn(events: Array) -> void:
	if _phase == PHASE_OVER:
		return
	_doubles_streak = 0
	_extra_roll = false
	_pending_space = -1
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


func _bankrupt_player(player_id: int, creditor: int, events: Array) -> void:
	var player := _players[player_id]
	if player.bankrupt:
		return
	player.bankrupt = true
	player.cash = 0
	player.in_jail = false
	for i in player.owned.size():
		var space_index := player.owned[i]
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
