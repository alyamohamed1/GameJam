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
const VICTORY_SCENE := preload("res://ui/victory.tscn")

const CIPHERTEXT := "lkbqtlpfu"

const LAPTOP_PASSWORD := "Schopenhaeur2025"
const SAFE_CODE := "126"

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
	elif p == Game.Phase.VICTORY:
		var victory := VICTORY_SCENE.instantiate()
		add_child(victory)
	elif p == Game.Phase.BLACKOUT and multiplayer.is_server():
		SFX.play("power_off")
		_apply_blackout()

func _apply_blackout() -> void:
	# Host-only. Darken the whole canvas with a CanvasModulate and attach a
	# small radial Light2D to the burglar so P1 can only see a few tiles
	# around themselves. Monitors on the client get a green tint via desk.gd.
	var dim := CanvasModulate.new()
	dim.name = "BlackoutDim"
	dim.color = Color(0.12, 0.12, 0.18)
	add_child(dim)
	var light := PointLight2D.new()
	light.name = "BurglarLight"
	light.texture = _make_radial_light_texture()
	light.texture_scale = 0.6
	light.energy = 1.6
	burglar.add_child(light)

func _make_radial_light_texture() -> Texture2D:
	var grad := Gradient.new()
	grad.add_point(0.0, Color(1, 1, 1, 1))
	grad.add_point(1.0, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	return tex

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
			"Exit":
				z.interacted.connect(_on_exit)
			_:
				z.interacted.connect(_on_zone_stub.bind(z))

func _on_fridge(_user: Node) -> void:
	SFX.play("note_pickup")
	_show_note("FRIDGE", "A sticky note: password is\n\nSchopenhaeur2025")

func _on_laptop(_user: Node) -> void:
	# Post-USB: laptop shows the encrypted file so P1 can read it to P2.
	if Game.phase >= Game.Phase.POST_USB:
		_show_note("LAPTOP SCREEN",
			"Encrypted file open on screen:\n\n%s\n\nRead it to the hacker." % CIPHERTEXT)
		return
	if Game.laptop_unlocked:
		_show_note("HOME LAPTOP", "Logged in. Plug the USB in.")
		return
	var modal: CanvasLayer = MODAL_PASSWORD.instantiate()
	add_child(modal)
	modal.setup("HOME LAPTOP")
	modal.submitted.connect(func(text: String) -> void:
		if text.strip_edges().to_lower() == LAPTOP_PASSWORD.to_lower():
			SFX.play("password_ok")
			Game.laptop_unlocked = true
			modal.close()
			_show_note("HOME LAPTOP", "LOGGED IN. Plug the USB in.")
		else:
			SFX.play("password_wrong")
			modal.set_status("Access denied.\nHint: check the fridge."))

func _on_usb(_user: Node) -> void:
	if not Game.laptop_unlocked:
		_show_note("USB PORT", "Laptop is locked. Find the password first.")
		return
	if Game.phase == Game.Phase.PRE_USB:
		SFX.play("usb")
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
			SFX.play("safe_open")
			SFX.play("victory_item")
			modal.close()
			Game.set_phase(Game.Phase.BLACKOUT)
			_show_note("SAFE", "Click. Safe opens. The lights go out.")
		else:
			SFX.play("safe_keypad")
			modal.set_status("Beep. Access denied."))

func _on_bookshelf(_user: Node) -> void:
	if Game.has_key:
		_show_note("BOOKSHELF", "The key is already in your pocket.")
		return
	Game.has_key = true
	SFX.play("note_pickup")
	_show_note("BOOKSHELF", "A heavy brass key. You pocketed it.")

func _on_bedroom_door(_user: Node, door: Node) -> void:
	if Game.door_unlocked:
		_show_note("BEDROOM DOOR", "Already open.")
		return
	if not Game.has_key:
		_show_note("BEDROOM DOOR", "Locked. You need a key.")
		return
	Game.door_unlocked = true
	SFX.play("door_creak")
	SFX.play("door_open", -4.0)
	door.unlock()
	_show_note("BEDROOM DOOR", "You turn the key. Door opens.")

func _on_exit(_user: Node) -> void:
	if Game.phase < Game.Phase.BLACKOUT:
		_show_note("FRONT DOOR", "Not without the loot. Crack the safe first.")
		return
	Game.set_phase(Game.Phase.VICTORY)

func _on_zone_stub(_user: Node, zone: Node) -> void:
	print("[host] interacted: %s (no handler yet)" % zone.label)

func _show_note(title: String, body: String) -> void:
	var modal: CanvasLayer = MODAL_NOTE.instantiate()
	add_child(modal)
	modal.setup(title, body)
