class_name GridwardEvents
extends RefCounted

## Event dictionaries queued by GridwardSim. `type` is one of the constants below.

const WAVE_STARTED: StringName = &"wave_started"
const ENEMY_SPAWNED: StringName = &"enemy_spawned"
const ENEMY_LEAKED: StringName = &"enemy_leaked"
const WAVE_CLEARED: StringName = &"wave_cleared"
const VICTORY: StringName = &"victory"
const DEFEAT: StringName = &"defeat"
const TOWER_PLACED: StringName = &"tower_placed"
const TOWER_SOLD: StringName = &"tower_sold"
const TOWER_UPGRADED: StringName = &"tower_upgraded"
const TOWER_FIRED: StringName = &"tower_fired"
const PROJECTILE_SPAWNED: StringName = &"projectile_spawned"
const PROJECTILE_IMPACT: StringName = &"projectile_impact"
const ENEMY_HIT: StringName = &"enemy_hit"
const ENEMY_KILLED: StringName = &"enemy_killed"


static func wave_started(wave_index: int, early_bonus: int) -> Dictionary:
	return {"type": WAVE_STARTED, "wave_index": wave_index, "early_bonus": early_bonus}


static func enemy_spawned(id: int, enemy_id: StringName, position: Vector2) -> Dictionary:
	return {
		"type": ENEMY_SPAWNED,
		"id": id,
		"enemy_id": enemy_id,
		"position": position,
	}


static func enemy_leaked(id: int, enemy_id: StringName, lives: int) -> Dictionary:
	return {
		"type": ENEMY_LEAKED,
		"id": id,
		"enemy_id": enemy_id,
		"lives": lives,
	}


static func wave_cleared(wave_index: int, bonus: int, gold: int) -> Dictionary:
	return {"type": WAVE_CLEARED, "wave_index": wave_index, "bonus": bonus, "gold": gold}


static func victory() -> Dictionary:
	return {"type": VICTORY}


static func defeat() -> Dictionary:
	return {"type": DEFEAT}


static func tower_placed(id: int, tower_id: StringName, cell: Vector2i, gold: int) -> Dictionary:
	return {
		"type": TOWER_PLACED,
		"id": id,
		"tower_id": tower_id,
		"cell": cell,
		"gold": gold,
	}


static func tower_sold(id: int, refund: int, gold: int) -> Dictionary:
	return {
		"type": TOWER_SOLD,
		"id": id,
		"refund": refund,
		"gold": gold,
	}


static func tower_upgraded(id: int, tier: int, cost: int, gold: int) -> Dictionary:
	return {
		"type": TOWER_UPGRADED,
		"id": id,
		"tier": tier,
		"cost": cost,
		"gold": gold,
	}


static func tower_fired(id: int, tower_id: StringName, target_id: int, kind: StringName) -> Dictionary:
	return {
		"type": TOWER_FIRED,
		"id": id,
		"tower_id": tower_id,
		"target_id": target_id,
		"kind": kind,
	}


static func projectile_spawned(id: int, tower_entity_id: int, position: Vector2, target_id: int) -> Dictionary:
	return {
		"type": PROJECTILE_SPAWNED,
		"id": id,
		"tower_entity_id": tower_entity_id,
		"position": position,
		"target_id": target_id,
	}


static func projectile_impact(id: int, position: Vector2, splash_radius: float) -> Dictionary:
	return {
		"type": PROJECTILE_IMPACT,
		"id": id,
		"position": position,
		"splash_radius": splash_radius,
	}


static func enemy_hit(id: int, damage: int, hp: int, tower_entity_id: int) -> Dictionary:
	return {
		"type": ENEMY_HIT,
		"id": id,
		"damage": damage,
		"hp": hp,
		"tower_entity_id": tower_entity_id,
	}


static func enemy_killed(id: int, enemy_id: StringName, bounty: int, gold: int) -> Dictionary:
	return {
		"type": ENEMY_KILLED,
		"id": id,
		"enemy_id": enemy_id,
		"bounty": bounty,
		"gold": gold,
	}
