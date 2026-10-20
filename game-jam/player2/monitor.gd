extends Control
# One CCTV monitor on the Player 2 desk. Owns a SubViewport sharing the
# shared world_2d, pointed at a fixed Camera2D over a specific room. A
# NO SIGNAL overlay sits on top; the desk toggles it per monitor based on
# game phase.

@export var cam_pos: Vector2 = Vector2.ZERO
@export var cam_zoom: float = 0.5
@export var room_label: String = ""
# True for the feeder-cam monitor (kitchen), which is live from the start.
@export var always_live: bool = false

@onready var _title: Label = $Title
@onready var _sub_viewport: SubViewport = $Container/SubViewport
@onready var _cam: Camera2D = $Container/SubViewport/Camera2D
@onready var _overlay: Control = $Overlay

var live: bool = false

func _ready() -> void:
	_sub_viewport.world_2d = get_tree().root.world_2d
	_cam.position = cam_pos
	_cam.zoom = Vector2(cam_zoom, cam_zoom)
	_cam.make_current()
	_title.text = room_label
	set_live(always_live)

func set_live(b: bool) -> void:
	live = b
	_overlay.visible = not b
