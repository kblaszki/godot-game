class_name AudioSpy
extends RefCounted

var calls: Array[Dictionary] = []


func play(sound_id: StringName, volume: float = 1.0) -> void:
	calls.append({"id": sound_id, "volume": volume})
