class_name ProjectileState
extends RefCounted

## One shell in flight. SPEED is cells per second for every projectile kind.

const SPEED := 6.0

var id: int = 0
var tower_entity_id: int = 0
var target_enemy_id: int = -1
var position: Vector2 = Vector2.ZERO
## Last aimed point. Updated while the target is alive.
var destination: Vector2 = Vector2.ZERO
var damage: int = 0
var splash_radius: float = 0.0
var anti_air: bool = false
var ground_only: bool = true
