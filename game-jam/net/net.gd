extends Node
# Autoload "Net". Handles host/join and scene swap once both peers connected.

const PORT := 7777
const MAX_CLIENTS := 1
const HOUSE_SCENE := "res://level/house.tscn"

signal status_changed(text: String)

func host() -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_CLIENTS)
	if err != OK:
		status_changed.emit("host failed: %s" % err)
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected_host)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	status_changed.emit("hosting on %d, waiting for client..." % PORT)

func join(ip: String) -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, PORT)
	if err != OK:
		status_changed.emit("join failed: %s" % err)
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_client)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	status_changed.emit("connecting to %s..." % ip)

func _on_peer_connected_host(_id: int) -> void:
	# Both peers in. Tell client to swap scenes, then swap on host.
	_load_house.rpc()
	_load_house()

func _on_connected_client() -> void:
	status_changed.emit("connected. waiting for host to start...")

func _on_connection_failed() -> void:
	status_changed.emit("connection failed")
	multiplayer.multiplayer_peer = null

func _on_peer_disconnected(_id: int) -> void:
	status_changed.emit("peer disconnected")

@rpc("authority", "call_local", "reliable")
func _load_house() -> void:
	get_tree().change_scene_to_file(HOUSE_SCENE)

# Host-triggered reload after FAIL. Resets host-only flags on each peer
# (laptop_unlocked only lives on host, but modal_open could be stuck true
# if a modal was open when FAIL fired).
@rpc("authority", "call_local", "reliable")
func restart() -> void:
	Game.modal_open = false
	Game.laptop_unlocked = false
	Game.has_key = false
	Game.door_unlocked = false
	Game.burglar_hidden = false
	Game.feeder_cooldown = 0.0
	get_tree().change_scene_to_file(HOUSE_SCENE)
