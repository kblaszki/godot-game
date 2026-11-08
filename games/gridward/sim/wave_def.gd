class_name WaveDef
extends RefCounted

## Ordered spawn groups. Each entry is a Dictionary:
## { "enemy_id": StringName, "count": int, "spacing_ticks": int, "delay_ticks": int }
var entries: Array[Dictionary] = []
