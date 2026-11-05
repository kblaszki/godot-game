class_name NetworkPort
extends RefCounted

## Future online transport. No-op in this build — hotseat uses LocalHotseatPort.


func is_online() -> bool:
	return false


func send_action(_action: Dictionary) -> void:
	pass


func poll_actions() -> Array:
	return []


func disconnect_session() -> void:
	pass
