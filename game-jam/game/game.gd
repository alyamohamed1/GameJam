extends Node
# Autoload "Game". Phase state owned by host; clients react via phase_changed.

enum Phase { LOBBY, PRE_USB, POST_USB, BLACKOUT, VICTORY, FAIL }

signal phase_changed(new_phase: int)

var phase: int = Phase.LOBBY

func set_phase(p: int) -> void:
	# Host-only. Broadcasts to all peers.
	if not multiplayer.is_server():
		return
	_apply_phase.rpc(p)

@rpc("authority", "call_local", "reliable")
func _apply_phase(p: int) -> void:
	phase = p
	phase_changed.emit(p)
