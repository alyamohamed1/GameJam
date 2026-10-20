extends CharacterBody2D
# Burglar. Host is authority: only host reads input and moves. Position
# syncs to client via MultiplayerSynchronizer sibling node. Also tracks the
# most-recently-entered Interactable zone and triggers it on interact input.

@export var speed: float = 60.0
@export var run_mult: float = 1.8

var _current_zone: Node = null

func _physics_process(_delta: float) -> void:
	# Guard: scene may load one frame before the ENet peer is fully active.
	# Calling is_server() in that window errors from enet_multiplayer_peer.cpp.
	var peer := multiplayer.multiplayer_peer
	if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	if not multiplayer.is_server():
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var s := speed
	if Input.is_action_pressed("run"):
		s *= run_mult
	velocity = dir * s
	move_and_slide()
	if Input.is_action_just_pressed("interact") and _current_zone != null:
		_current_zone.trigger(self)

# Called by Interactable on body_entered/body_exited.
func set_current_zone(z: Node) -> void:
	_current_zone = z

func clear_current_zone(z: Node) -> void:
	if _current_zone == z:
		_current_zone = null
