class_name BoardSpace
extends RefCounted

const KIND_GO := "go"
const KIND_PROPERTY := "property"
const KIND_TAX := "tax"
const KIND_JAIL := "jail"
const KIND_GOTO_JAIL := "goto_jail"
const KIND_FREE := "free"

var kind: String = KIND_FREE
var name: String = ""
var group: int = -1
var price: int = 0
var rent: int = 0
var tax: int = 0


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


static func make_go(p_name: String = "Plaza") -> BoardSpace:
	return BoardSpace.new(KIND_GO, p_name)


static func make_property(p_name: String, p_group: int, p_price: int, p_rent: int) -> BoardSpace:
	return BoardSpace.new(KIND_PROPERTY, p_name, p_group, p_price, p_rent)


static func make_tax(p_name: String, amount: int) -> BoardSpace:
	return BoardSpace.new(KIND_TAX, p_name, -1, 0, 0, amount)


static func make_jail(p_name: String = "Holding") -> BoardSpace:
	return BoardSpace.new(KIND_JAIL, p_name)


static func make_goto_jail(p_name: String = "Exile") -> BoardSpace:
	return BoardSpace.new(KIND_GOTO_JAIL, p_name)


static func make_free(p_name: String = "Park") -> BoardSpace:
	return BoardSpace.new(KIND_FREE, p_name)
