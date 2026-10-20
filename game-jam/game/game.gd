extends Node
# Autoload "Game". Phase state is host-authoritative and replicates to the
# client via an RPC. Host-only flags (modal_open, laptop_unlocked for now)
# stay local to the host because the client has no need for them yet.
# Feeder cooldown is a shared float: host authors it, broadcasts on change,
# both peers tick it down locally so the client's Feeder button countdown
# stays in sync without constant RPC spam.

enum Phase { LOBBY, PRE_USB, POST_USB, BLACKOUT, VICTORY, FAIL }

signal phase_changed(new_phase: int)
signal noise_at(pos: Vector2)

var phase: int = Phase.LOBBY
var modal_open: bool = false
var laptop_unlocked: bool = false
# Set true when burglar picks up the key from the Living bookshelf.
var has_key: bool = false
# Set true when burglar uses the key on the bedroom door.
var door_unlocked: bool = false

const FEEDER_COOLDOWN := 20.0
const FEEDER_EAT_TIME := 5.0
var feeder_cooldown: float = 0.0

func _process(delta: float) -> void:
	if feeder_cooldown > 0.0:
		feeder_cooldown = max(0.0, feeder_cooldown - delta)

# ---- Phase ----

func set_phase(p: int) -> void:
	if not multiplayer.is_server():
		return
	_apply_phase.rpc(p)

@rpc("authority", "call_local", "reliable")
func _apply_phase(p: int) -> void:
	phase = p
	phase_changed.emit(p)

# ---- Feeder ----

# Called from any peer (typically client). Routed to host for validation.
func request_feeder() -> void:
	_server_request_feeder.rpc_id(1)

@rpc("any_peer", "reliable")
func _server_request_feeder() -> void:
	if not multiplayer.is_server():
		return
	if feeder_cooldown > 0.0:
		return
	var dog := get_tree().get_first_node_in_group("dog")
	var feeder := get_tree().get_first_node_in_group("feeder")
	if dog == null or feeder == null:
		return
	dog.distract_at(feeder.global_position)
	_apply_feeder_cooldown.rpc(FEEDER_COOLDOWN)

@rpc("authority", "call_local", "reliable")
func _apply_feeder_cooldown(d: float) -> void:
	feeder_cooldown = d
