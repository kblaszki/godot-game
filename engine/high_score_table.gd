class_name HighScoreTable
extends RefCounted

var _capacity: int
var _scores: Array[int] = []


func _init(capacity: int = 10) -> void:
	_capacity = maxi(0, capacity)


func capacity() -> int:
	return _capacity


func qualifies(score: int) -> bool:
	if _capacity == 0:
		return false
	if score < 0:
		return false
	if _scores.size() < _capacity:
		return true
	return score > _scores[_scores.size() - 1]


func insert(score: int) -> int:
	if not qualifies(score):
		return -1
	var rank := 0
	while rank < _scores.size() and _scores[rank] >= score:
		rank += 1
	_scores.insert(rank, score)
	if _scores.size() > _capacity:
		_scores.pop_back()
	return rank


func entries() -> Array[int]:
	return _scores.duplicate()
