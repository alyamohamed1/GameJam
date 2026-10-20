extends Node2D
# Shared world. World size 1200x900, visuals come from art/map.png scaled
# 0.829x. Walls, furniture colliders, and zone positions are placed in the
# editor on top of the map (StaticBody2D + CollisionShape2D for walls,
# Interactable + hide spots for zones). debug_collisions_hint is forced on
# in Game autoload so colliders show as red outlines at runtime.

const DESK_SCENE := preload("res://player2/desk.tscn")
const MODAL_NOTE := preload("res://ui/modal_note.tscn")
const MODAL_PASSWORD := preload("res://ui/modal_password.tscn")
const FAIL_SCENE := preload("res://ui/fail.tscn")
const FOG_SCENE := preload("res://level/fog.tscn")

const LAPTOP_PASSWORD := "Biscuit2019"
const SAFE_CODE := "7294"

@onready var zones_root: Node2D = $Zones
@onready var burglar: Node2D = $Burglar

func _ready() -> void:
	Game.phase_changed.connect(_on_phase_changed)
	if multiplayer.is_server():
		var cam := Camera2D.new()
		cam.name = "HostCam"
		cam.position_smoothing_enabled = true
		cam.position_smoothing_speed = 8.0
		burglar.add_child(cam)
		cam.make_current()
		_connect_zones()
		var fog := FOG_SCENE.instantiate()
		add_child(fog)
		Game.set_phase(Game.Phase.PRE_USB)
	else:
		var desk := DESK_SCENE.instantiate()
		add_child(desk)

func _on_phase_changed(p: int) -> void:
	if p == Game.Phase.FAIL:
		var fail := FAIL_SCENE.instantiate()
		add_child(fail)

# ---- Puzzle wiring (host only) ----

func _connect_zones() -> void:
	for z in zones_root.get_children():
		if not z.has_signal("interacted"):
			continue
		match String(z.name):
			"Fridge":
				z.interacted.connect(_on_fridge)
			"Laptop":
				z.interacted.connect(_on_laptop)
			"UsbPort":
				z.interacted.connect(_on_usb)
			"Safe":
				z.interacted.connect(_on_safe)
			"Bookshelf":
				z.interacted.connect(_on_bookshelf)
			"BedroomDoor":
				z.interacted.connect(_on_bedroom_door.bind(z))
			_:
				z.interacted.connect(_on_zone_stub.bind(z))

func _on_fridge(_user: Node) -> void:
	_show_note("FRIDGE", "A sticky note: password is\n\nBiscuit2019")

func _on_laptop(_user: Node) -> void:
	if Game.laptop_unlocked:
		_show_note("HOME LAPTOP", "Logged in. Plug the USB in.")
		return
	var modal: CanvasLayer = MODAL_PASSWORD.instantiate()
	add_child(modal)
	modal.setup("HOME LAPTOP")
	modal.submitted.connect(func(text: String) -> void:
		if text.strip_edges().to_lower() == LAPTOP_PASSWORD.to_lower():
			Game.laptop_unlocked = true
			modal.close()
			_show_note("HOME LAPTOP", "LOGGED IN. Plug the USB in.")
		else:
			modal.set_status("Access denied.\nHint: where the milk lives."))

func _on_usb(_user: Node) -> void:
	if not Game.laptop_unlocked:
		_show_note("USB PORT", "Laptop is locked. Find the password first.")
		return
	if Game.phase == Game.Phase.PRE_USB:
		Game.set_phase(Game.Phase.POST_USB)
		_show_note("USB PORT", "USB plugged in. Hacker is online.")
	else:
		_show_note("USB PORT", "USB already plugged in.")

func _on_safe(_user: Node) -> void:
	if Game.phase < Game.Phase.POST_USB:
		_show_note("SAFE", "Keypad is dead. Need the hacker to decrypt the code first.")
		return
	if Game.phase >= Game.Phase.BLACKOUT:
		_show_note("SAFE", "Already open.")
		return
	var modal: CanvasLayer = MODAL_PASSWORD.instantiate()
	add_child(modal)
	modal.setup("SAFE KEYPAD", "4-digit code", false)
	modal.submitted.connect(func(text: String) -> void:
		if text.strip_edges() == SAFE_CODE:
			modal.close()
			Game.set_phase(Game.Phase.BLACKOUT)
			_show_note("SAFE", "Click. Safe opens. The lights go out.")
		else:
			modal.set_status("Beep. Access denied."))

func _on_bookshelf(_user: Node) -> void:
	if Game.has_key:
		_show_note("BOOKSHELF", "The key is already in your pocket.")
		return
	Game.has_key = true
	_show_note("BOOKSHELF", "A heavy brass key. You pocketed it.")

func _on_bedroom_door(_user: Node, door: Node) -> void:
	if Game.door_unlocked:
		_show_note("BEDROOM DOOR", "Already open.")
		return
	if not Game.has_key:
		_show_note("BEDROOM DOOR", "Locked. You need a key.")
		return
	Game.door_unlocked = true
	door.unlock()
	_show_note("BEDROOM DOOR", "You turn the key. Door opens.")

func _on_zone_stub(_user: Node, zone: Node) -> void:
	print("[host] interacted: %s (no handler yet)" % zone.label)

func _show_note(title: String, body: String) -> void:
	var modal: CanvasLayer = MODAL_NOTE.instantiate()
	add_child(modal)
	modal.setup(title, body)
