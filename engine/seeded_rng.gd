class_name SeededRng
extends RefCounted

var _rng: RandomNumberGenerator


func _init(p_seed: int = 0) -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = p_seed


func randf() -> float:
	return _rng.randf()


func randi_range(from: int, to: int) -> int:
	return _rng.randi_range(from, to)


func randf_range(from: float, to: float) -> float:
	return _rng.randf_range(from, to)
