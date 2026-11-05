class_name ChanceDeck
extends RefCounted

var _cards: Array[Dictionary] = []
var _index: int = 0


func _init(rng: SeededRng = null) -> void:
	_cards = _default_cards()
	if rng != null:
		shuffle(rng)


func shuffle(rng: SeededRng) -> void:
	for i in range(_cards.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Dictionary = _cards[i]
		_cards[i] = _cards[j]
		_cards[j] = tmp
	_index = 0


func draw() -> Dictionary:
	if _cards.is_empty():
		return {"effect": "noop", "label": "Nothing"}
	if _index >= _cards.size():
		_index = 0
	var card: Dictionary = _cards[_index]
	_index += 1
	return card.duplicate(true)


static func _default_cards() -> Array[Dictionary]:
	return [
		{"effect": "gain", "amount": 100, "label": "Tax rebate +$100"},
		{"effect": "gain", "amount": 50, "label": "Found cash +$50"},
		{"effect": "lose", "amount": 50, "label": "Speeding fine -$50"},
		{"effect": "lose", "amount": 100, "label": "Repairs -$100"},
		{"effect": "goto_go", "label": "Advance to Plaza Gate"},
		{"effect": "jail", "label": "Go to Lost Island"},
		{"effect": "steal", "amount": 50, "label": "Collect $50 from each rival"},
		{"effect": "get_out", "label": "Get out of Island free"},
		{"effect": "move", "steps": 3, "label": "Advance 3 spaces"},
		{"effect": "move", "steps": -3, "label": "Go back 3 spaces"},
	]
