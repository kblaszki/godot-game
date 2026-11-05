extends "res://lab/layered_host.gd"

const SETUP_PATH := "res://games/districts/app/setup.tscn"

var match_players: int = 2
var match_bot_mask: int = 0
var match_seed: int = 1
var match_table_stake: int = 1


func _boot() -> void:
	submit(SceneRequest.replace(SETUP_PATH))


func configure_match(player_count: int, bot_mask: int, seed_value: int = 1, table_stake: int = 1) -> void:
	match_players = clampi(player_count, 2, 4)
	match_bot_mask = bot_mask
	match_seed = seed_value
	match_table_stake = maxi(table_stake, 1)


func _on_quit_requested() -> void:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("return_to_launcher"):
			node.call_deferred("return_to_launcher")
			return
		node = node.get_parent()
	get_tree().quit()
