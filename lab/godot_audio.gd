class_name GodotAudio
extends Node

const VOICES := 8

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	for _i in VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func register_blip(sound_id: StringName, hz: float, seconds: float) -> void:
	var sample_rate := 22050
	var sample_count := maxi(1, int(round(float(sample_rate) * seconds)))
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var attack := 0.005
	var release := 0.03
	for i in sample_count:
		var t := float(i) / float(sample_rate)
		var envelope := 1.0
		if t < attack:
			envelope = t / attack
		elif t > seconds - release:
			envelope = maxf(0.0, (seconds - t) / release)
		var phase := fmod(t * hz, 1.0)
		var raw := 1.0 if phase < 0.5 else -1.0
		var sample := int(clampf(raw * 0.35 * envelope, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	_streams[sound_id] = stream


func play(sound_id: StringName, volume: float = 1.0) -> void:
	if not _streams.has(sound_id) or _players.is_empty():
		return
	var stream: AudioStreamWAV = _streams[sound_id]
	var gain := clampf(volume, 0.0, 1.0)
	var db := -80.0 if gain <= 0.0001 else linear_to_db(gain)
	for player in _players:
		if not player.playing:
			player.stream = stream
			player.volume_db = db
			player.play()
			return
	var steal: AudioStreamPlayer = _players[0]
	steal.stop()
	steal.stream = stream
	steal.volume_db = db
	steal.play()
