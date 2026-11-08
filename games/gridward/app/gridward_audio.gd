class_name GridwardAudio
extends Node

## Maps GridwardEvents to cue ids. Headless sessions use NullAudio.
## A windowed play session uses GodotAudio blips. Tests may set_port.

const CUE_HIT: StringName = &"hit"
const CUE_KILL: StringName = &"kill"
const CUE_KILL_BIG: StringName = &"kill_big"
const CUE_LEAK: StringName = &"leak"
const CUE_FIRE: StringName = &"fire"
const CUE_IMPACT: StringName = &"impact"
const CUE_PLACE: StringName = &"place"
const CUE_SELL: StringName = &"sell"
const CUE_UPGRADE: StringName = &"upgrade"
const CUE_WAVE: StringName = &"wave"
const CUE_CLEAR: StringName = &"clear"
const CUE_VICTORY: StringName = &"victory"
const CUE_DEFEAT: StringName = &"defeat"

const BIG_KILL_BOUNTY := 50
const HIT_STOP_STEPS := 4
const TRAUMA_LEAK := 0.62
const TRAUMA_BIG_KILL := 0.34
const TRAUMA_DEFEAT := 0.75

var _port: Object = null


func _ready() -> void:
	if _port != null:
		return
	if OS.has_feature("headless") or DisplayServer.get_name() == "headless":
		_port = NullAudio.new()
		return
	var live := GodotAudio.new()
	add_child(live)
	live.register_blip(CUE_HIT, 880.0, 0.03)
	live.register_blip(CUE_KILL, 520.0, 0.06)
	live.register_blip(CUE_KILL_BIG, 180.0, 0.12)
	live.register_blip(CUE_LEAK, 140.0, 0.16)
	live.register_blip(CUE_FIRE, 660.0, 0.025)
	live.register_blip(CUE_IMPACT, 220.0, 0.05)
	live.register_blip(CUE_PLACE, 440.0, 0.04)
	live.register_blip(CUE_SELL, 300.0, 0.05)
	live.register_blip(CUE_UPGRADE, 720.0, 0.06)
	live.register_blip(CUE_WAVE, 500.0, 0.05)
	live.register_blip(CUE_CLEAR, 840.0, 0.08)
	live.register_blip(CUE_VICTORY, 960.0, 0.14)
	live.register_blip(CUE_DEFEAT, 110.0, 0.2)
	_port = live


func set_port(port: Object) -> void:
	_port = port


func play_cue(cue: StringName, volume: float = 1.0) -> void:
	if cue == &"" or _port == null:
		return
	if _port.has_method("play"):
		_port.call("play", cue, volume)


## Presentation recipe for one sim event. Does not touch the sim or any RNG.
static func reaction(event: Dictionary) -> Dictionary:
	var kind: StringName = event.get("type", &"")
	var cue: StringName = &""
	var volume := 1.0
	var trauma := 0.0
	var hit_stop := 0
	var vfx: StringName = &""
	match kind:
		GridwardEvents.ENEMY_HIT:
			cue = CUE_HIT
			volume = 0.4
			vfx = &"hit_flash"
		GridwardEvents.ENEMY_KILLED:
			var bounty := int(event.get("bounty", 0))
			var big := StringName(event.get("enemy_id", &"")) == &"boss" or bounty >= BIG_KILL_BOUNTY
			cue = CUE_KILL_BIG if big else CUE_KILL
			volume = 1.0 if big else 0.7
			if big:
				trauma = TRAUMA_BIG_KILL
				hit_stop = HIT_STOP_STEPS
			vfx = &"death_pop"
		GridwardEvents.ENEMY_LEAKED:
			cue = CUE_LEAK
			trauma = TRAUMA_LEAK
		GridwardEvents.TOWER_FIRED:
			cue = CUE_FIRE
			volume = 0.55
			vfx = &"tracer"
		GridwardEvents.PROJECTILE_IMPACT:
			cue = CUE_IMPACT
			volume = 0.65
			vfx = &"impact"
		GridwardEvents.TOWER_PLACED:
			cue = CUE_PLACE
			volume = 0.8
		GridwardEvents.TOWER_SOLD:
			cue = CUE_SELL
			volume = 0.7
		GridwardEvents.TOWER_UPGRADED:
			cue = CUE_UPGRADE
			volume = 0.75
		GridwardEvents.WAVE_STARTED:
			cue = CUE_WAVE
			volume = 0.6
		GridwardEvents.WAVE_CLEARED:
			cue = CUE_CLEAR
			volume = 0.7
		GridwardEvents.VICTORY:
			cue = CUE_VICTORY
		GridwardEvents.DEFEAT:
			cue = CUE_DEFEAT
			trauma = TRAUMA_DEFEAT
		_:
			pass
	return {
		"cue": cue,
		"volume": volume,
		"trauma": trauma,
		"hit_stop": hit_stop,
		"vfx": vfx,
	}
