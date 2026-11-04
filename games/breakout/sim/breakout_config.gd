class_name BreakoutConfig
extends RefCounted

var court_width: float = 800.0
var court_height: float = 450.0
var paddle_width: float = 80.0
var paddle_height: float = 12.0
## Horizontal paddle speed in pixels per second.
var paddle_speed: float = 420.0
## Distance from court bottom to paddle center.
var paddle_margin_bottom: float = 28.0
var ball_radius: float = 6.0
## Constant ball speed in pixels per second.
var ball_speed: float = 320.0
var brick_rows: int = 5
var brick_cols: int = 10
var brick_width: float = 64.0
var brick_height: float = 18.0
var brick_gap: float = 4.0
## Top of first brick row from court top.
var brick_offset_top: float = 40.0
var start_lives: int = 3
var points_per_brick: int = 10
