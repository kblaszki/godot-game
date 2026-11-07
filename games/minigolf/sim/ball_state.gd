class_name BallState
extends RefCounted

var pos: Vector2 = Vector2.ZERO
var vel: Vector2 = Vector2.ZERO
var radius: float = 0.04
var sunk: bool = false
var strokes: int = 0
var last_fairway: Vector2 = Vector2.ZERO


func speed() -> float:
	return vel.length()


func copy_from(other: BallState) -> void:
	pos = other.pos
	vel = other.vel
	radius = other.radius
	sunk = other.sunk
	strokes = other.strokes
	last_fairway = other.last_fairway
