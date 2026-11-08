extends GutTest

## 60 Hz caps. The clear test allows 20 minutes of match time.
const _CLEAR_CAP := 60 * 60 * 20
const _SWEEP_CAP := 60 * 60 * 10
const _DETERMINISM_TICKS := 60 * 60
## BUILD ticks in a row with no wave start. Spending a few ticks is expected.
const _BUILD_STUCK := 180


func test_bot_should_clear_meadow_normal() -> void:
	var sim := _meadow(1)
	var run := _drive(sim, _CLEAR_CAP)
	assert_eq(sim.get_phase(), GridwardSim.Phase.VICTORY, _outcome(sim, int(run["ticks"])))


func test_bot_same_seed_should_be_deterministic() -> void:
	var left := _meadow(4)
	var right := _meadow(4)
	_drive(left, _DETERMINISM_TICKS)
	_drive(right, _DETERMINISM_TICKS)
	assert_eq(_snapshot(left), _snapshot(right))


func test_bot_seed_sweep_should_not_softlock() -> void:
	for seed_value in range(1, 11):
		var sim := _meadow(seed_value)
		var run := _drive(sim, _SWEEP_CAP)
		assert_lt(int(run["streak"]), _BUILD_STUCK, _outcome(sim, int(run["ticks"])))
		assert_true(
			sim.get_wave_index() > 0 or sim.get_phase() != GridwardSim.Phase.BUILD,
			_outcome(sim, int(run["ticks"]))
		)


func _meadow(seed_value: int) -> GridwardSim:
	return GridwardSim.new(GridwardCatalog.build_meadow(), GridwardCatalog.new(), seed_value)


func _drive(sim: GridwardSim, cap: int) -> Dictionary:
	var bot := GridwardBot.new(sim, GridwardCatalog.new())
	var ticks := 0
	var streak := 0
	var max_streak := 0
	while ticks < cap:
		var phase := sim.get_phase()
		if phase == GridwardSim.Phase.VICTORY or phase == GridwardSim.Phase.DEFEAT:
			break
		bot.act()
		sim.drain_events()
		phase = sim.get_phase()
		if phase == GridwardSim.Phase.BUILD:
			streak += 1
			if streak > max_streak:
				max_streak = streak
		else:
			streak = 0
		if phase == GridwardSim.Phase.VICTORY or phase == GridwardSim.Phase.DEFEAT:
			break
		sim.step()
		sim.drain_events()
		ticks += 1
	return {"ticks": ticks, "streak": max_streak}


func _snapshot(sim: GridwardSim) -> String:
	var parts := PackedStringArray()
	parts.append(str(sim.get_phase()))
	parts.append(str(sim.get_gold()))
	parts.append(str(sim.get_lives()))
	parts.append(str(sim.get_wave_index()))
	parts.append(str(sim.get_enemies().size()))
	for tower in sim.get_towers():
		var state := tower as TowerState
		parts.append("%s@%s/%s" % [state.tower_id, state.cell, state.tier])
	return "|".join(parts)


func _outcome(sim: GridwardSim, ticks: int) -> String:
	return "phase %s wave %s lives %s gold %s ticks %s towers %s" % [
		sim.get_phase(),
		sim.get_wave_index(),
		sim.get_lives(),
		sim.get_gold(),
		ticks,
		_snapshot(sim),
	]
