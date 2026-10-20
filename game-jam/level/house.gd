extends Node2D
# Shared world (Stage 1 redesign). 7 rooms built from the gamejam map:
# Kitchen, Living, Hallway, Office, Bathroom, Bedroom, plus a Closet nook
# in the top-right of the Kitchen. Walls built procedurally from doorway
# gaps so tweaking a door position doesn't require touching the .tscn.

const DESK_SCENE := preload("res://player2/desk.tscn")
const MODAL_NOTE := preload("res://ui/modal_note.tscn")
const MODAL_PASSWORD := preload("res://ui/modal_password.tscn")
const FAIL_SCENE := preload("res://ui/fail.tscn")

const LAPTOP_PASSWORD := "Biscuit2019"
const SAFE_CODE := "7294"

const WORLD_SIZE := Vector2(1200, 900)
const WALL_THICKNESS := 10.0
const DOORWAY_WIDTH := 60.0
const WALL_COLOR := Color(0.08, 0.08, 0.1, 1.0)

@onready var walls_root: Node2D = $Walls
@onready var zones_root: Node2D = $Zones
@onready var burglar: Node2D = $Burglar

func _ready() -> void:
	_build_walls()
	Game.phase_changed.connect(_on_phase_changed)
	if multiplayer.is_server():
		var cam := Camera2D.new()
		cam.name = "HostCam"
		cam.position_smoothing_enabled = true
		cam.position_smoothing_speed = 8.0
		burglar.add_child(cam)
		cam.make_current()
		_connect_zones()
		Game.set_phase(Game.Phase.PRE_USB)
	else:
		var desk := DESK_SCENE.instantiate()
		add_child(desk)

func _on_phase_changed(p: int) -> void:
	if p == Game.Phase.FAIL:
		var fail := FAIL_SCENE.instantiate()
		add_child(fail)

# ---- Walls ----

func _build_walls() -> void:
	# Perimeter.
	_add_wall_h(0.0, WORLD_SIZE.x, 0.0)
	_add_wall_h(0.0, WORLD_SIZE.x, WORLD_SIZE.y - WALL_THICKNESS)
	_add_wall_v(0.0, WORLD_SIZE.y, 0.0)
	_add_wall_v(0.0, WORLD_SIZE.y, WORLD_SIZE.x - WALL_THICKNESS)

	# Kitchen bottom / Living top (y=400). Door K-L at x=130.
	for seg in _segments_with_gaps(0.0, 400.0, [130.0]):
		_add_wall_h(seg.x, seg.y, 400.0 - WALL_THICKNESS * 0.5)

	# Office bottom / Bathroom top (y=350). Door Office-Bathroom at x=1000.
	for seg in _segments_with_gaps(760.0, 1200.0, [1000.0]):
		_add_wall_h(seg.x, seg.y, 350.0 - WALL_THICKNESS * 0.5)

	# Bathroom bottom / Bedroom top (y=605). Solid, no doorway.
	_add_wall_h(760.0, 1200.0 - 760.0, 605.0 - WALL_THICKNESS * 0.5)

	# Closet partition (y=80) within Kitchen. Door at x=360.
	for seg in _segments_with_gaps(320.0, 400.0, [360.0]):
		_add_wall_h(seg.x, seg.y, 80.0 - WALL_THICKNESS * 0.5)

	# Closet west wall (x=320), solid, y=0..80.
	_add_wall_v(0.0, 80.0, 320.0 - WALL_THICKNESS * 0.5)

	# Kitchen+Living right / Hallway left (x=400). Doors at y=200 (K-H) and
	# y=650 (L-H).
	for seg in _segments_with_gaps(0.0, 900.0, [200.0, 650.0]):
		_add_wall_v(seg.x, seg.y, 400.0 - WALL_THICKNESS * 0.5)

	# Hallway right / Right rooms left (x=750). Doors at y=180 (Office-H)
	# and y=750 (Bedroom-H). The bedroom door opening stays physically open
	# in this wall; the lockable BedroomDoor node spawned separately fills
	# the opening while locked.
	for seg in _segments_with_gaps(0.0, 900.0, [180.0, 750.0]):
		_add_wall_v(seg.x, seg.y, 750.0 - WALL_THICKNESS * 0.5)

func _segments_with_gaps(axis_start: float, axis_end: float, gap_centers: Array) -> Array:
	var cursor := axis_start
	var segs: Array = []
	var half := DOORWAY_WIDTH * 0.5
	var centers := gap_centers.duplicate()
	centers.sort()
	for c in centers:
		var gap_start: float = float(c) - half
		var gap_end: float = float(c) + half
		if gap_start > cursor:
			segs.append(Vector2(cursor, gap_start - cursor))
		cursor = gap_end
	if cursor < axis_end:
		segs.append(Vector2(cursor, axis_end - cursor))
	return segs

func _add_wall_h(x_start: float, length: float, y: float) -> void:
	_add_wall(Rect2(x_start, y, length, WALL_THICKNESS))

func _add_wall_v(y_start: float, length: float, x: float) -> void:
	_add_wall(Rect2(x, y_start, WALL_THICKNESS, length))

func _add_wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.position + rect.size * 0.5
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	shape.shape = rs
	body.add_child(shape)
	var visual := ColorRect.new()
	visual.offset_left = -rect.size.x * 0.5
	visual.offset_top = -rect.size.y * 0.5
	visual.offset_right = rect.size.x * 0.5
	visual.offset_bottom = rect.size.y * 0.5
	visual.color = WALL_COLOR
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(visual)
	walls_root.add_child(body)

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

func _on_zone_stub(_user: Node, zone: Node) -> void:
	print("[host] interacted: %s (no handler yet)" % zone.label)

func _show_note(title: String, body: String) -> void:
	var modal: CanvasLayer = MODAL_NOTE.instantiate()
	add_child(modal)
	modal.setup(title, body)
