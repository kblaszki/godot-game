class_name MinigolfBot
extends RefCounted


static func pick_aim_power(sim: MinigolfSim) -> Dictionary:
	var hole := sim.get_hole()
	var ball := sim.get_ball()
	var config := sim.get_config()
	var to_cup := hole.cup_xz() - ball.pos
	var dist := to_cup.length()
	var dir := Vector2(0, 1) if dist < 0.0001 else to_cup.normalized()
	# Seeded noise so bots are not identical clones across seats, but same seed matches.
	var rng := sim.get_rng()
	var angle := rng.randf_range(-0.12, 0.12)
	var cos_a := cos(angle)
	var sin_a := sin(angle)
	dir = Vector2(dir.x * cos_a - dir.y * sin_a, dir.x * sin_a + dir.y * cos_a).normalized()
	var power := clampf(dist / config.max_impulse, 0.15, 1.0)
	power = clampf(power + rng.randf_range(-0.05, 0.05), 0.1, 1.0)
	return {"dir": dir, "power": power}
