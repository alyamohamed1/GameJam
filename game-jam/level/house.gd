extends Node2D
# Shared world. World size 1200x900, visuals come from art/map.png scaled
# 0.829x. Walls, furniture colliders, and zone positions are placed in the
# editor on top of the map (StaticBody2D + CollisionShape2D for walls,
# Interactable + hide spots for zones). debug_collisions_hint is forced on
# in Game autoload so colliders show as red outlines at runtime.

const DESK_SCENE := preload("res://player2/desk.tscn")
const MODAL_NOTE := preload("res://ui/modal_note.tscn")
const MODAL_PASSWORD := preload("res://ui/modal_password.tscn")
const MODAL_IMAGE := preload("res://ui/modal_image.tscn")
const FRIDGE_NOTE_TEX := preload("res://art/fridgenote_inspect.png")
const SHELF_TEX := preload("res://art/Shelf.png")
const LAPTOP_STATES_TEX := preload("res://art/P1_laptop_5_states.png")

# Shelf.png is 1774x887, two states side-by-side (887x887 each). Left = no key,
# Right = with key visible.
const SHELF_LEFT := Rect2(0, 0, 887, 887)
const SHELF_RIGHT := Rect2(887, 0, 887, 887)

# P1_laptop_5_states.png is 1536x1024, 3 cols x 2 rows of 512x512 cells.
const LAPTOP_OFF := Rect2(0, 0, 512, 512)
const LAPTOP_INPUT := Rect2(512, 0, 512, 512)
const LAPTOP_INPUT_HINT := Rect2(1024, 0, 512, 512)
const LAPTOP_DESKTOP := Rect2(0, 512, 512, 512)
const LAPTOP_GLITCH := Rect2(512, 512, 512, 512)

const MAP_DARK_TEX := preload("res://art/house_dark.png")
const MAP_NIGHTVISION_TEX := preload("res://art/house_nightvision.png")
const FAIL_SCENE := preload("res://ui/fail.tscn")
const FOG_SCENE := preload("res://level/fog.tscn")
const VICTORY_SCENE := preload("res://ui/victory.tscn")

const CIPHERTEXT := "lkbqtlpfu"

const LAPTOP_PASSWORD := "Schopenhaeur2025"
const SAFE_CODE := "126"

@onready var zones_root: Node2D = $Zones
@onready var burglar: Node2D = $Burglar

var _laptop_wrong_tried: bool = false

func _ready() -> void:
	Game.phase_changed.connect(_on_phase_changed)
	_show_phase_hint(Game.Phase.PRE_USB)
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
	_show_phase_hint(p)
	if p == Game.Phase.FAIL:
		var fail := FAIL_SCENE.instantiate()
		add_child(fail)
	elif p == Game.Phase.VICTORY:
		var victory := VICTORY_SCENE.instantiate()
		add_child(victory)
	elif p == Game.Phase.BLACKOUT:
		if multiplayer.is_server():
			SFX.play("power_off")
			_swap_map_texture(MAP_DARK_TEX)
			_apply_blackout()
		else:
			_swap_map_texture(MAP_NIGHTVISION_TEX)

func _swap_map_texture(tex: Texture2D) -> void:
	var map_node := get_node_or_null("Map") as Sprite2D
	if map_node:
		map_node.texture = tex

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
	light.texture_scale = 0.22
	light.energy = 1.5
	light.blend_mode = Light2D.BLEND_MODE_ADD
	burglar.add_child(light)

func _make_radial_light_texture() -> Texture2D:
	# Smooth radial fade with a soft midpoint so the lit area reads as a
	# round pool of light instead of a hard square.
	var grad := Gradient.new()
	grad.add_point(0.0, Color(1, 1, 1, 1))
	grad.add_point(0.55, Color(1, 1, 1, 0.45))
	grad.add_point(1.0, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 512
	tex.height = 512
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
	_show_image("FRIDGE", FRIDGE_NOTE_TEX)
	Hints.show_host("laptop's in the office. type the password you just read.")

func _on_laptop(_user: Node) -> void:
	if Game.phase >= Game.Phase.POST_USB:
		_show_image("LAPTOP", LAPTOP_STATES_TEX, LAPTOP_GLITCH,
			"Ciphertext: %s   (read to hacker)" % CIPHERTEXT)
		return
	if Game.laptop_unlocked:
		_show_image("LAPTOP", LAPTOP_STATES_TEX, LAPTOP_DESKTOP, "Logged in. Plug the USB in.")
		return
	var modal: CanvasLayer = MODAL_PASSWORD.instantiate()
	add_child(modal)
	modal.setup("HOME LAPTOP")
	var region: Rect2 = LAPTOP_INPUT_HINT if _laptop_wrong_tried else LAPTOP_INPUT
	modal.set_image(LAPTOP_STATES_TEX, region)
	modal.submitted.connect(func(text: String) -> void:
		if text.strip_edges().to_lower() == LAPTOP_PASSWORD.to_lower():
			SFX.play("password_ok")
			Game.laptop_unlocked = true
			modal.close()
			_show_image("LAPTOP", LAPTOP_STATES_TEX, LAPTOP_DESKTOP, "LOGGED IN. Plug the USB in.")
		else:
			SFX.play("password_wrong")
			_laptop_wrong_tried = true
			modal.set_image(LAPTOP_STATES_TEX, LAPTOP_INPUT_HINT)
			modal.set_status("Access denied. Hint: where the milk lives."))

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
	modal.setup("SAFE KEYPAD", "3-digit code", false)
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
		_show_image("BOOKSHELF", SHELF_TEX, SHELF_LEFT, "Already searched.")
		return
	var img: CanvasLayer = MODAL_IMAGE.instantiate()
	add_child(img)
	img.setup("BOOKSHELF", SHELF_TEX, SHELF_RIGHT, "A brass key tucked between the books.", "Take Key")
	img.action_pressed.connect(func() -> void:
		Game.has_key = true
		SFX.play("note_pickup")
		Hints.show_host("key pocketed. bedroom door's unlocked now."))

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

func _show_phase_hint(p: int) -> void:
	match p:
		Game.Phase.PRE_USB:
			Hints.show_host("find a laptop. password's hidden somewhere obvious.")
			Hints.show_client("waiting on the burglar to boot a terminal.")
		Game.Phase.POST_USB:
			Hints.show_host("hacker's in. find the safe and crack it.")
			Hints.show_client("you're online. open the laptop, dig for the safe code.")
		Game.Phase.BLACKOUT:
			Hints.show_host("lights out. slip through to the front door.")
			Hints.show_client("night vision up. call out the dog on your monitors.")
		Game.Phase.VICTORY, Game.Phase.FAIL:
			Hints.clear()

func _show_note(title: String, body: String) -> void:
	var modal: CanvasLayer = MODAL_NOTE.instantiate()
	add_child(modal)
	modal.setup(title, body)

func _show_image(title: String, texture: Texture2D, region: Rect2 = Rect2(), caption: String = "") -> void:
	var modal: CanvasLayer = MODAL_IMAGE.instantiate()
	add_child(modal)
	modal.setup(title, texture, region, caption, "")
