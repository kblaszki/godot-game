extends Control

const LAUNCHER_PATH := "res://lab/launcher.tscn"

var _settings: LabSettings = LabSettings.new()

@onready var _resolution_value: Label = $Center/Column/ResolutionRow/Value
@onready var _mode_button: Button = $Center/Column/ModeButton
@onready var _prev: Button = $Center/Column/ResolutionRow/Prev
@onready var _next: Button = $Center/Column/ResolutionRow/Next
@onready var _back: Button = $Center/Column/Back


func _ready() -> void:
	_settings = SettingsStore.load(SettingsStore.DEFAULT_PATH)
	_prev.pressed.connect(_on_prev_pressed)
	_next.pressed.connect(_on_next_pressed)
	_mode_button.pressed.connect(_on_mode_pressed)
	_back.pressed.connect(_on_back_pressed)
	_refresh()
	_back.grab_focus()


func _on_prev_pressed() -> void:
	_cycle_resolution(-1)
	_persist_and_apply()


func _on_next_pressed() -> void:
	_cycle_resolution(1)
	_persist_and_apply()


func _on_mode_pressed() -> void:
	if _settings.mode == LabSettings.MODE_FULLSCREEN:
		_settings.mode = LabSettings.MODE_WINDOWED
	else:
		_settings.mode = LabSettings.MODE_FULLSCREEN
	_persist_and_apply()


func _on_back_pressed() -> void:
	_submit(SceneRequest.replace(LAUNCHER_PATH))


func _cycle_resolution(delta: int) -> void:
	var idx := 0
	for i in LabSettings.RESOLUTIONS.size():
		if LabSettings.RESOLUTIONS[i] == _settings.resolution:
			idx = i
			break
	var count := LabSettings.RESOLUTIONS.size()
	idx = (idx + delta) % count
	if idx < 0:
		idx += count
	_settings.resolution = LabSettings.RESOLUTIONS[idx]


func _persist_and_apply() -> void:
	SettingsStore.save(SettingsStore.DEFAULT_PATH, _settings)
	WindowApplier.apply(_settings, get_window())
	_refresh()


func _refresh() -> void:
	_resolution_value.text = "%d×%d" % [_settings.resolution.x, _settings.resolution.y]
	if _settings.mode == LabSettings.MODE_FULLSCREEN:
		_mode_button.text = "Mode: Fullscreen"
	else:
		_mode_button.text = "Mode: Windowed"


func _submit(req: SceneRequest) -> void:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("submit"):
			node.call("submit", req)
			return
		node = node.get_parent()
