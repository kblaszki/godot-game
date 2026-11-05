class_name DistrictBot
extends RefCounted

## Keep at least this much cash after a purchase.
const CASH_BUFFER := 200
## Prefer buys when rent is at least this fraction of price.
const MIN_RENT_RATIO := 0.08
const BUILD_CASH_THRESHOLD := 350


static func should_buy(sim: DistrictSim, player_id: int) -> bool:
	if sim.get_phase() != DistrictSim.PHASE_BUY:
		return false
	var pending := sim.get_pending_space()
	if pending < 0:
		return false
	var player := sim.get_player(player_id)
	if player.bankrupt or not player.is_bot:
		return false
	var space := sim.get_config().space_at(pending)
	if space.kind != BoardSpace.KIND_PROPERTY:
		return false
	if player.cash < space.price + CASH_BUFFER:
		return false
	if space.price <= 0:
		return false
	var ratio := float(space.rent) / float(space.price)
	return ratio >= MIN_RENT_RATIO


static func should_build(sim: DistrictSim, player_id: int, space_index: int) -> bool:
	var player := sim.get_player(player_id)
	if player.bankrupt or not player.is_bot:
		return false
	if not player.owns(space_index):
		return false
	var space := sim.get_config().space_at(space_index)
	if space.kind != BoardSpace.KIND_PROPERTY:
		return false
	if sim.get_config().require_monopoly_to_build and not sim.has_monopoly(player_id, space.group):
		return false
	if sim.get_build_level(space_index) >= space.max_builds:
		return false
	return player.cash >= space.build_cost + BUILD_CASH_THRESHOLD


static func pick_tour_target(sim: DistrictSim, player_id: int) -> int:
	var best := 0
	var best_score := 999999
	var config := sim.get_config()
	for i in config.space_count():
		var space := config.space_at(i)
		if space.kind != BoardSpace.KIND_PROPERTY:
			continue
		var owner := sim.get_owner(i)
		var score := space.price
		if owner == -1:
			score -= 80
		elif owner != player_id:
			score += sim.current_rent(i) * 4
		else:
			score -= 40
		if score < best_score:
			best_score = score
			best = i
	return best


static func auction_bid_amount(sim: DistrictSim, player_id: int) -> int:
	if not should_buy_like(sim, player_id, sim.get_auction_space()):
		return 0
	var space := sim.get_config().space_at(sim.get_auction_space())
	var bid := sim.get_auction_high_bid() + 10
	var player := sim.get_player(player_id)
	if bid > space.price or player.cash < bid + CASH_BUFFER:
		return 0
	return bid


static func should_buy_like(sim: DistrictSim, player_id: int, space_index: int) -> bool:
	var player := sim.get_player(player_id)
	if player.bankrupt or space_index < 0:
		return false
	var space := sim.get_config().space_at(space_index)
	if space.kind != BoardSpace.KIND_PROPERTY or space.price <= 0:
		return false
	if player.cash < space.price + CASH_BUFFER:
		return false
	var ratio := float(space.rent) / float(space.price)
	return ratio >= MIN_RENT_RATIO


static func pick_gadget(sim: DistrictSim, player_id: int) -> String:
	var player := sim.get_player(player_id)
	if sim.get_gadget_uses_left(player_id) <= 0:
		return ""
	if int(player.gadgets.get(GadgetRules.SHIELD, 0)) > 0 and player.shield_charges <= 0:
		return GadgetRules.SHIELD
	return ""
