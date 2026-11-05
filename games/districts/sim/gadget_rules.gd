class_name GadgetRules
extends RefCounted

const SHIELD := "shield"
const DOUBLE_RENT := "double_rent"
const REROLL := "reroll"
const STEAL_CASH := "steal_cash"
const FREEZE := "freeze"

const ALL: Array[String] = [SHIELD, DOUBLE_RENT, REROLL, STEAL_CASH, FREEZE]


static func starter_kit() -> Dictionary:
	return {
		SHIELD: 1,
		DOUBLE_RENT: 1,
		REROLL: 1,
		STEAL_CASH: 1,
		FREEZE: 1,
	}
