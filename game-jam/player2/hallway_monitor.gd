extends Control
# Hallway CCTV in the same rectangular format as other monitors. Camera
# shows the hallway's full width; up/down buttons pan vertically while
# held. Camera position clamps to the hallway rect so view can't leak.

@export var room_rect: Rect2 = Rect2(540, 10, 190, 890)
@export var room_label: String = "HALLWAY"
@export var always_live: bool = false
@export var pan_speed: float = 220.0

@onready var _title: Label = $Title
@onready var _sub_viewport: SubViewport = $Clip/Container/SubViewport
@onready var _cam: Camera2D = $Clip/Container/SubViewport/Camera2D
@onready var _overlay: Control = $Overlay
@onready var _up_btn: Button = $Buttons/Up
@onready var _down_btn: Button = $Buttons/Down

var live: bool = false
var _min_y: float = 0.0
var _max_y: float = 0.0

func _ready() -> void:
	_sub_viewport.world_2d = get_tree().root.world_2d
	_title.text = room_label
	_configure_camera()
	set_live(always_live)

func _configure_camera() -> void:
	var vp_size := Vector2(_sub_viewport.size)
	# Fit hallway width exactly inside the viewport. View height = whatever
	# that scale makes it; we scroll vertically.
	var scale: float = vp_size.x / room_rect.size.x
	_cam.zoom = Vector2(scale, scale)
	var view_half_y: float = (vp_size.y / scale) * 0.5
	_min_y = room_rect.position.y + view_half_y
	_max_y = room_rect.position.y + room_rect.size.y - view_half_y
	# Clamp both bounds so clip-only hallways still render.
	if _min_y > _max_y:
		var mid := (room_rect.position.y + room_rect.size.y * 0.5)
		_min_y = mid
		_max_y = mid
	_cam.position = Vector2(
		room_rect.position.x + room_rect.size.x * 0.5,
		clamp(room_rect.position.y + room_rect.size.y * 0.5, _min_y, _max_y),
	)
	_cam.make_current()

func _process(delta: float) -> void:
	if not live:
		return
	var dir := 0.0
	if _up_btn.button_pressed:
		dir -= 1.0
	if _down_btn.button_pressed:
		dir += 1.0
	if dir != 0.0:
		_cam.position.y = clamp(_cam.position.y + dir * pan_speed * delta, _min_y, _max_y)

func set_live(b: bool) -> void:
	live = b
	_overlay.visible = not b
	_up_btn.disabled = not b
	_down_btn.disabled = not b
