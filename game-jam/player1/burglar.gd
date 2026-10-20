extends CharacterBody2D
# Burglar. Host is authority: only host reads input and moves. Position
# syncs to client via MultiplayerSynchronizer sibling node.

@export var speed: float = 60.0
@export var run_mult: float = 1.8

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
