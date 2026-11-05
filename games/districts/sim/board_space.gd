class_name BoardSpace
extends RefCounted

const KIND_GO := "go"
const KIND_PROPERTY := "property"
const KIND_TAX := "tax"
const KIND_JAIL := "jail"
const KIND_GOTO_JAIL := "goto_jail"
const KIND_FREE := "free"
const KIND_CHANCE := "chance"
const KIND_TOUR := "tour"
const KIND_ARENA := "arena"

var kind: String = KIND_FREE
var name: String = ""
var group: int = -1
var price: int = 0
var rent: int = 0
var tax: int = 0
var tax_percent: float = 0.0
var rent_tiers: PackedInt32Array = PackedInt32Array()
var build_cost: int = 0
var max_builds: int = 4


func _init(
	p_kind: String = KIND_FREE,
	p_name: String = "",
	p_group: int = -1,
	p_price: int = 0,
	p_rent: int = 0,
	p_tax: int = 0
) -> void:
	kind = p_kind
	name = p_name
	group = p_group
	price = p_price
	rent = p_rent
	tax = p_tax
	if p_rent > 0 and rent_tiers.is_empty():
		rent_tiers = PackedInt32Array([p_rent, p_rent * 2, p_rent * 3, p_rent * 4, p_rent * 5])
		build_cost = maxi(p_price / 2, 50)
		max_builds = 4


static func make_go(p_name: String = "Plaza") -> BoardSpace:
	return BoardSpace.new(KIND_GO, p_name)


static func make_property(p_name: String, p_group: int, p_price: int, p_rent: int) -> BoardSpace:
	return BoardSpace.new(KIND_PROPERTY, p_name, p_group, p_price, p_rent)


static func make_tax(p_name: String, amount: int, percent: float = 0.0) -> BoardSpace:
	var space := BoardSpace.new(KIND_TAX, p_name, -1, 0, 0, amount)
	space.tax_percent = percent
	return space


static func make_jail(p_name: String = "Holding") -> BoardSpace:
	return BoardSpace.new(KIND_JAIL, p_name)


static func make_goto_jail(p_name: String = "Exile") -> BoardSpace:
	return BoardSpace.new(KIND_GOTO_JAIL, p_name)


static func make_free(p_name: String = "Park") -> BoardSpace:
	return BoardSpace.new(KIND_FREE, p_name)


static func make_chance(p_name: String = "Chance") -> BoardSpace:
	return BoardSpace.new(KIND_CHANCE, p_name)


static func make_tour(p_name: String = "World Tour") -> BoardSpace:
	return BoardSpace.new(KIND_TOUR, p_name)


static func make_arena(p_name: String = "Championships") -> BoardSpace:
	return BoardSpace.new(KIND_ARENA, p_name)


func rent_at_level(level: int) -> int:
	if rent_tiers.is_empty():
		return rent
	var idx := clampi(level, 0, rent_tiers.size() - 1)
	return rent_tiers[idx]
