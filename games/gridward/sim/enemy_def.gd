class_name EnemyDef
extends RefCounted

## Tier-0 enemy stats at wave 1, difficulty Normal. HP scale lives on GridwardConfig.

var id: StringName = &""
var hp: int = 0
## Movement speed in cells per second.
var speed: float = 0.0
var bounty: int = 0
var armor: int = 0
var is_air: bool = false
var is_group: bool = false
var is_boss: bool = false
