extends Control

const PLAY_PATH := "res://games/breakout/app/play.tscn"
const SCORE_PATH := "user://scores/breakout.txt"
const SCORE_CAPACITY := 10

const BRICK_TEXES: Array[Texture2D] = [
	preload("res://games/breakout/assets/brick_0.png"),
	preload("res://games/breakout/assets/brick_1.png"),
	preload("res://games/breakout/assets/brick_2.png"),
	preload("res://games/breakout/assets/brick_3.png"),
	preload("res://games/breakout/assets/brick_4.png"),
]

var _time: float = 0.0
var _decor_sprites: Array[Sprite2D] = []

@onready var _best: Label = $Center/Column/Best
@onready var _title: Label = $Center/Column/Title
@onready var _glow: ColorRect = $Glow
@onready var _decor: Node2D = $Decor
@onready var _start: Button = $Center/Column/Start
@onready var _quit: Button = $Center/Column/Quit


func _ready() -> void:
	_start.pressed.connect(_on_start_pressed)
	_quit.pressed.connect(_on_quit_pressed)
	_refresh_best()
	_spawn_decor()
	_start.grab_focus()


func _process(delta: float) -> void:
	_time += delta
	_title.modulate = Color(1, 1, 1, 0.88 + 0.12 * sin(_time * 2.2))
	_glow.color.a = 0.14 + 0.08 * (0.5 + 0.5 * sin(_time * 1.1))
	var vp := get_viewport_rect().size
	for i in _decor_sprites.size():
		var sprite: Sprite2D = _decor_sprites[i]
		var base_y: float = sprite.get_meta("base_y")
		sprite.position.y = base_y + sin(_time * 1.6 + float(i) * 0.7) * 10.0
		sprite.position.x = fposmod(sprite.position.x + delta * sprite.get_meta("drift"), vp.x + 80.0) - 40.0


func _spawn_decor() -> void:
	var vp := get_viewport_rect().size
	for i in 12:
		var sprite := Sprite2D.new()
		sprite.texture = BRICK_TEXES[i % BRICK_TEXES.size()]
		sprite.centered = true
		sprite.scale = Vector2(2.4, 2.4)
		sprite.modulate = Color(1, 1, 1, 0.18)
		sprite.position = Vector2(fmod(float(i) * 137.0, vp.x), 80.0 + float(i % 4) * 70.0)
		sprite.set_meta("base_y", sprite.position.y)
		sprite.set_meta("drift", 18.0 + float(i % 5) * 6.0)
		_decor.add_child(sprite)
		_decor_sprites.append(sprite)


func _refresh_best() -> void:
	var entries: Array[int] = ScoreStore.load(SCORE_PATH, SCORE_CAPACITY).entries()
	var best := entries[0] if entries.size() > 0 else 0
	_best.text = "Best  %d" % best


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
