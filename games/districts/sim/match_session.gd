class_name MatchSession
extends RefCounted

## Wraps DistrictSim with a NetworkPort. Online matchmaking is out of scope;
## LocalHotseatPort keeps all actions local.

var sim: DistrictSim
var port: NetworkPort
var table_stake: int = 1


func _init(p_sim: DistrictSim = null, p_port: NetworkPort = null) -> void:
	sim = p_sim if p_sim != null else DistrictSim.new()
	port = p_port if p_port != null else LocalHotseatPort.new()


func start(player_count: int, bot_mask: int = 0, seed_value: int = 1) -> void:
	var config := sim.get_config()
	config.table_stake = maxi(table_stake, 1)
	config.apply_stake()
	sim.setup(player_count, bot_mask, seed_value)


func dispatch(action: Dictionary) -> Array:
	port.send_action(action)
	var kind := str(action.get("type", ""))
	match kind:
		"roll":
			return sim.roll()
		"buy":
			return sim.buy()
		"skip":
			return sim.skip()
		"end_manage":
			return sim.end_manage()
		"build":
			return sim.build(int(action.get("space", -1)))
		"sell_build":
			return sim.sell_build(int(action.get("space", -1)))
		"tour":
			return sim.pick_tour_target(int(action.get("space", -1)))
		"arena":
			return sim.resolve_arena()
		"chance":
			return sim.resolve_chance()
		"auction_bid":
			return sim.auction_bid(int(action.get("amount", 0)))
		"auction_pass":
			return sim.auction_pass()
		"gadget":
			return sim.use_gadget(str(action.get("gadget", "")), int(action.get("target", -1)))
		"bot_act":
			return sim.bot_act()
		_:
			return []
