extends Node
# Autoload "Game". Phase state is host-authoritative and replicates to the
# client via an RPC. Host-only flags (modal_open, laptop_unlocked for now)
# stay local to the host because the client has no need for them yet.

enum Phase { LOBBY, PRE_USB, POST_USB, BLACKOUT, VICTORY, FAIL }

signal phase_changed(new_phase: int)

# Emitted on the host by the burglar when running. The dog listens and
# switches to INVESTIGATE if the noise falls within hearing range.
signal noise_at(pos: Vector2)

var phase: int = Phase.LOBBY

# Host-only. True while any blocking modal (laptop password, fridge note,
# safe keypad, ...) is open; the burglar freezes while it's true.
var modal_open: bool = false

# Host-only. Set true once the correct laptop password has been entered.
var laptop_unlocked: bool = false

func set_phase(p: int) -> void:
	if not multiplayer.is_server():
		return
	_apply_phase.rpc(p)

@rpc("authority", "call_local", "reliable")
func _apply_phase(p: int) -> void:
	phase = p
	phase_changed.emit(p)
