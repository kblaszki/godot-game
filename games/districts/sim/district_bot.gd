class_name DistrictBot
extends RefCounted

## Keep at least this much cash after a purchase.
const CASH_BUFFER := 200
## Prefer buys when rent is at least this fraction of price.
const MIN_RENT_RATIO := 0.08


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
