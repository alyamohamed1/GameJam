extends Control
# One CCTV monitor. Owns a SubViewport sharing world_2d, pointed at a
# Camera2D centered on the room. A Polygon2D parent with clip_children
# masks the viewport texture to the exact shape of the room — trace the
# polygon in the editor to match the painted room outline.
# Clicking the monitor emits `clicked` with the Monitor node so the desk
# can open a semi-fullscreen view.

signal clicked(monitor: Node)

@export var room_rect: Rect2 = Rect2(0, 0, 100, 100)
@export var room_label: String = ""
@export var always_live: bool = false

@onready var _title: Label = $Title
@onready var _sub_viewport: SubViewport = $Clip/Container/SubViewport
@onready var _cam: Camera2D = $Clip/Container/SubViewport/Camera2D
@onready var _overlay: Control = $Overlay

var live: bool = false

func _ready() -> void:
	_sub_viewport.world_2d = get_tree().root.world_2d
	_title.text = room_label
	_configure_camera()
	set_live(always_live)
	# Catch clicks on the whole monitor box.
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(self)

func _configure_camera() -> void:
	# Zoom so the room fits inside the SubViewport uniformly. Any letterbox
	# is hidden by the Clip Polygon2D (trace it per room in the editor).
	var vp_size := Vector2(_sub_viewport.size)
	var scale: float = min(vp_size.x / room_rect.size.x, vp_size.y / room_rect.size.y)
	_cam.position = room_rect.position + room_rect.size * 0.5
	_cam.zoom = Vector2(scale, scale)
	_cam.make_current()

func set_live(b: bool) -> void:
	live = b
	_overlay.visible = not b
