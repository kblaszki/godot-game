class_name MinigolfAudio
extends Node

## Plays named cues when wavs exist under assets/sfx/; otherwise no-ops.


func play_cue(cue: String) -> void:
	if OS.has_feature("headless") or DisplayServer.get_name() == "headless":
		return
	var path := "res://games/minigolf/assets/sfx/%s.wav" % cue
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
