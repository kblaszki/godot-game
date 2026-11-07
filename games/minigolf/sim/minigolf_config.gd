class_name MinigolfConfig
extends RefCounted

var tick: float = FixedTick.SEC
var ball_radius: float = 0.04
var max_impulse: float = 4.5
var friction: float = 1.8
var restitution: float = 0.55
var stop_eps: float = 0.05
var sink_speed: float = 0.35
var cup_radius: float = 0.08
var min_players: int = 1
var max_players: int = 4
var max_ticks_per_stroke: int = 60 * 20
var ball_moved_every: int = 3
var course_id: String = "fairway_park"


func max_strokes_for_par(par: int) -> int:
	return par + 4
