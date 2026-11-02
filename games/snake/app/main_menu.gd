extends Control

const PLAY_PATH := "res://games/snake/app/play.tscn"
const SCORE_PATH := "user://scores/snake.txt"
const SCORE_CAPACITY := 10

@onready var _best: Label = $Center/Column/Best
@onready var _start: Button = $Center/Column/Start
@onready var _quit: Button = $Center/Column/Quit


func _ready() -> void:
	_start.pressed.connect(_on_start_pressed)
	_quit.pressed.connect(_on_quit_pressed)
	_refresh_best()
	_start.grab_focus()


func _refresh_best() -> void:
	var entries: Array[int] = ScoreStore.load(SCORE_PATH, SCORE_CAPACITY).entries()
	var best := entries[0] if entries.size() > 0 else 0
	_best.text = "Best: %d" % best


func _on_start_pressed() -> void:
	_submit(SceneRequest.replace(PLAY_PATH))


func _on_quit_pressed() -> void:
	_submit(SceneRequest.quit())


func _submit(req: SceneRequest) -> void:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("submit"):
			node.call("submit", req)
			return
		node = node.get_parent()
