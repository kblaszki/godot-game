class_name SnakeConfig
extends RefCounted

## Grid width in cells.
var width: int = 20
## Grid height in cells.
var height: int = 15
## Pixel size of one cell (presentation only; sim ignores it).
var cell: float = 24.0
## Move once every this many fixed ticks.
var move_every_ticks: int = 6
## Initial body length including the head.
var start_length: int = 3
