class_name PongConfig
extends RefCounted

## Playfield width in pixels. Origin is the top-left; +x points right.
var court_width: float = 800.0
## Playfield height in pixels. +y points down.
var court_height: float = 450.0
var paddle_height: float = 80.0
var paddle_width: float = 12.0
## Left paddle speed in pixels per second.
var paddle_speed: float = 420.0
var ball_radius: float = 8.0
## Constant ball speed in pixels per second.
var ball_speed: float = 360.0
var win_score: int = 5
## Right paddle tracking speed in pixels per second.
var ai_speed: float = 320.0
