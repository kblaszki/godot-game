extends Control

const LAUNCHER_PATH := "res://lab/launcher.tscn"
const SHEET_PNG := "res://assets/pixel_demo/demo_sprites.png"
const SHEET_JSON := "res://assets/pixel_demo/demo_sprites.json"
const ANIM_PNG := "res://assets/pixel_demo/anims/coin_spin.png"
const ANIM_JSON := "res://assets/pixel_demo/anims/coin_spin.json"
const DISPLAY_SCALE := 4

const SLIME_VARIANTS: Array[StringName] = [&"slime", &"slime_red", &"slime_blue"]

var _sheet: PxlSheet
var _anim: PxlSheet
var _sheet_tex: Texture2D
var _anim_tex: Texture2D
var _slime_index: int = 0
var _anim_index: int = 0
var _anim_elapsed_ms: float = 0.0
var _last_replace_path: String = ""

@onready var _grid: GridContainer = $Margin/Column/Scroll/Grid
@onready var _variant_btn: Button = $Margin/Column/Buttons/Variant
@onready var _back_btn: Button = $Margin/Column/Buttons/Back
@onready var _coin_rect: TextureRect = $Margin/Column/AnimRow/Coin
@onready var _status: Label = $Margin/Column/Status


func _ready() -> void:
	texture_filter = TEXTURE_FILTER_NEAREST
	_sheet_tex = load(SHEET_PNG) as Texture2D
	_anim_tex = load(ANIM_PNG) as Texture2D
	_sheet = PxlSheet.parse(FileAccess.get_file_as_string(SHEET_JSON))
	_anim = PxlSheet.parse(FileAccess.get_file_as_string(ANIM_JSON))
	_variant_btn.pressed.connect(_on_variant_pressed)
	_back_btn.pressed.connect(_on_back_pressed)
	_rebuild_grid()
	_apply_slime_variant()
	_apply_anim_frame(0)
	_status.text = "frames: %d · coin frames: %d" % [
		_sheet.frame_names().size() if _sheet.is_valid() else 0,
		_anim.frame_names().size() if _anim.is_valid() else 0,
	]
	_back_btn.grab_focus()


func _process(delta: float) -> void:
	if _anim == null or not _anim.is_valid():
		return
	var names := _anim.tag_frames(&"coin_spin")
	if names.is_empty():
		names = _anim.frame_names()
	if names.is_empty():
		return
	_anim_elapsed_ms += delta * 1000.0
	var dur := float(_anim.frame_duration_ms(StringName(names[_anim_index])))
	if _anim_elapsed_ms >= dur:
		_anim_elapsed_ms = 0.0
		_anim_index = (_anim_index + 1) % names.size()
		_apply_anim_frame(_anim_index)


func sheet_frame_count() -> int:
	if _sheet == null or not _sheet.is_valid():
		return 0
	return _sheet.frame_names().size()


func cycle_variant() -> StringName:
	_slime_index = (_slime_index + 1) % SLIME_VARIANTS.size()
	_apply_slime_variant()
	return SLIME_VARIANTS[_slime_index]


func last_replace_path() -> String:
	return _last_replace_path


func _on_variant_pressed() -> void:
	cycle_variant()


func _on_back_pressed() -> void:
	_last_replace_path = LAUNCHER_PATH
	_submit(SceneRequest.replace(LAUNCHER_PATH))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()


func _rebuild_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()
	if _sheet == null or not _sheet.is_valid() or _sheet_tex == null:
		return
	for name in _sheet.frame_names():
		var cell := VBoxContainer.new()
		cell.alignment = BoxContainer.ALIGNMENT_CENTER
		var tr := TextureRect.new()
		tr.texture_filter = TEXTURE_FILTER_NEAREST
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var rect := _sheet.frame_rect(StringName(name))
		var atlas := AtlasTexture.new()
		atlas.atlas = _sheet_tex
		atlas.region = Rect2(rect)
		tr.texture = atlas
		tr.custom_minimum_size = Vector2(rect.size) * float(DISPLAY_SCALE)
		var label := Label.new()
		label.text = String(name)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 12)
		cell.add_child(tr)
		cell.add_child(label)
		_grid.add_child(cell)


func _apply_slime_variant() -> void:
	if _sheet == null or not _sheet.is_valid() or _sheet_tex == null:
		return
	var name := SLIME_VARIANTS[_slime_index]
	_variant_btn.text = "Variant: %s" % String(name)
	# Highlight by rebuilding status; grid already shows all variants.


func _apply_anim_frame(index: int) -> void:
	if _anim == null or not _anim.is_valid() or _anim_tex == null:
		return
	var names := _anim.tag_frames(&"coin_spin")
	if names.is_empty():
		names = _anim.frame_names()
	if names.is_empty():
		return
	index = clampi(index, 0, names.size() - 1)
	var rect := _anim.frame_rect(StringName(names[index]))
	var atlas := AtlasTexture.new()
	atlas.atlas = _anim_tex
	atlas.region = Rect2(rect)
	_coin_rect.texture = atlas
	_coin_rect.custom_minimum_size = Vector2(rect.size) * float(DISPLAY_SCALE)


func _submit(req: SceneRequest) -> void:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("submit"):
			node.call("submit", req)
			return
		node = node.get_parent()
