extends Node2D
# Shared world. Builds walls procedurally (easier to tune than hand-authored
# .tscn SubResources). Host adds a follow Camera2D to the burglar. Client
# swaps to the desk UI.

const DESK_SCENE := preload("res://player2/desk.tscn")

# World size: 960 x 540 = two viewport widths/heights (viewport is 480 x 270).
const WORLD_SIZE := Vector2(960, 540)
const WALL_THICKNESS := 8.0
const DOORWAY_WIDTH := 48.0
const WALL_COLOR := Color(0.08, 0.08, 0.1, 1.0)

@onready var walls_root: Node2D = $Walls
@onready var zones_root: Node2D = $Zones
@onready var burglar: Node2D = $Burglar

func _ready() -> void:
	_build_walls()
	if multiplayer.is_server():
		var cam := Camera2D.new()
		cam.name = "HostCam"
		cam.position_smoothing_enabled = true
		cam.position_smoothing_speed = 8.0
		burglar.add_child(cam)
		cam.make_current()
		_connect_zones()
	else:
		var desk := DESK_SCENE.instantiate()
		get_tree().root.call_deferred("add_child", desk)

func _connect_zones() -> void:
	for z in zones_root.get_children():
		if z.has_signal("interacted"):
			z.interacted.connect(_on_zone_interacted.bind(z))

func _on_zone_interacted(_user: Node, zone: Node) -> void:
	print("[host] interacted: %s" % zone.label)

# Build perimeter + interior walls with doorway gaps. Each wall segment is a
# StaticBody2D with a RectangleShape2D collider plus a matching ColorRect so
# it's visible without art assets. Doorways are expressed as (segment_pos,
# segment_length) pairs returned from _segments_with_gaps.
func _build_walls() -> void:
	# Perimeter (no gaps).
	_add_wall_h(0.0, WORLD_SIZE.x, 0.0)
	_add_wall_h(0.0, WORLD_SIZE.x, WORLD_SIZE.y - WALL_THICKNESS)
	_add_wall_v(0.0, WORLD_SIZE.y, 0.0)
	_add_wall_v(0.0, WORLD_SIZE.y, WORLD_SIZE.x - WALL_THICKNESS)

	# Middle horizontal wall at y = 270 between top row and bottom row.
	# Doorways centered at x = 160 (Kitchen <-> Entrance),
	# x = 480 (Living <-> Hallway), x = 800 (Bedroom <-> Empty).
	var mid_y := 270.0 - WALL_THICKNESS * 0.5
	for seg in _segments_with_gaps(0.0, WORLD_SIZE.x, [160.0, 480.0, 800.0]):
		_add_wall_h(seg.x, seg.y, mid_y)

	# Vertical wall at x = 320 (Kitchen|Living, Entrance|Hallway).
	# One doorway per row, centered vertically in each row (y = 135 and y = 405).
	var left_vx := 320.0 - WALL_THICKNESS * 0.5
	for seg in _segments_with_gaps(0.0, WORLD_SIZE.y, [135.0, 405.0]):
		_add_wall_v(seg.x, seg.y, left_vx)

	# Vertical wall at x = 640 (Living|Bedroom, Hallway|Empty).
	var right_vx := 640.0 - WALL_THICKNESS * 0.5
	for seg in _segments_with_gaps(0.0, WORLD_SIZE.y, [135.0, 405.0]):
		_add_wall_v(seg.x, seg.y, right_vx)

# Returns a list of (start, length) Vector2 segments covering [axis_start,
# axis_end], with DOORWAY_WIDTH-wide gaps centered at each value in gap_centers.
func _segments_with_gaps(axis_start: float, axis_end: float, gap_centers: Array) -> Array:
	var cursor := axis_start
	var segs: Array = []
	var half := DOORWAY_WIDTH * 0.5
	# Sort gap_centers ascending just in case.
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
