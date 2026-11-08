class_name GridwardEvents
extends RefCounted

## Event dictionaries queued by GridwardSim. `type` is one of the constants below.

const WAVE_STARTED: StringName = &"wave_started"
const ENEMY_SPAWNED: StringName = &"enemy_spawned"
const ENEMY_LEAKED: StringName = &"enemy_leaked"
const WAVE_CLEARED: StringName = &"wave_cleared"
const VICTORY: StringName = &"victory"
const DEFEAT: StringName = &"defeat"


static func wave_started(wave_index: int) -> Dictionary:
	return {"type": WAVE_STARTED, "wave_index": wave_index}


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


static func wave_cleared(wave_index: int) -> Dictionary:
	return {"type": WAVE_CLEARED, "wave_index": wave_index}


static func victory() -> Dictionary:
	return {"type": VICTORY}


static func defeat() -> Dictionary:
	return {"type": DEFEAT}
