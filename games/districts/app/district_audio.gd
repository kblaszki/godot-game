class_name DistrictAudio
extends Node

## Named cue player. Missing wav files no-op. Headless sessions use NullAudio.

const CUE_PATHS := {
	"dice": "res://games/districts/assets/sfx/dice.wav",
	"hop": "res://games/districts/assets/sfx/hop.wav",
	"buy": "res://games/districts/assets/sfx/buy.wav",
	"cash": "res://games/districts/assets/sfx/cash.wav",
	"build": "res://games/districts/assets/sfx/build.wav",
	"shake": "res://games/districts/assets/sfx/shake.wav",
	"chance": "res://games/districts/assets/sfx/chance.wav",
}

var _port: Object = null
var _player: AudioStreamPlayer
var _streams: Dictionary = {}


func _ready() -> void:
	if OS.has_feature("headless") or DisplayServer.get_name() == "headless":
		_port = NullAudio.new()
		return
	_player = AudioStreamPlayer.new()
	add_child(_player)
	for cue in CUE_PATHS.keys():
		var path := str(CUE_PATHS[cue])
		if not ResourceLoader.exists(path):
			continue
		var stream: Resource = load(path)
		if stream is AudioStream:
			_streams[cue] = stream


func set_port(port: Object) -> void:
	_port = port


func play_cue(cue: String, volume: float = 1.0) -> void:
	if cue == "":
		return
	if _port != null and _port.has_method("play"):
		_port.call("play", StringName(cue), volume)
		return
	if _player == null or not _streams.has(cue):
		return
	_player.stream = _streams[cue]
	var gain := clampf(volume, 0.001, 1.0)
	_player.volume_db = linear_to_db(gain)
	_player.play()
