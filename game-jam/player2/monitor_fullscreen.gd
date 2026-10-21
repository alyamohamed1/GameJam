extends CanvasLayer
# Semi-fullscreen monitor viewer. Shown when P2 clicks any CCTV monitor
# on the desk. Hosts its own SubViewport sharing world_2d, pointed at
# the source monitor's room_rect but zoomed up to fill most of the
# window. Close with the X button, Esc, or clicking the dim backdrop.

signal closed

@export var room_rect: Rect2 = Rect2(0, 0, 100, 100)
@export var room_label: String = ""

@onready var _title: Label = $Root/Bezel/Title
@onready var _sub_viewport: SubViewport = $Root/Bezel/Container/SubViewport
@onready var _cam: Camera2D = $Root/Bezel/Container/SubViewport/Camera2D
@onready var _dim: ColorRect = $Root/Dim
@onready var _close_btn: Button = $Root/Bezel/CloseBtn

func _ready() -> void:
	_sub_viewport.world_2d = get_tree().root.world_2d
	_title.text = room_label
	_configure_camera()
	_close_btn.pressed.connect(_close)
	_dim.gui_input.connect(_on_dim_input)
	SFX.play("p2_mouse", -8.0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()

func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close()

func _close() -> void:
	SFX.play("p2_click")
	closed.emit()
	queue_free()

func _configure_camera() -> void:
	# Fullscreen uses the larger scale (fill the bezel's screen area even
	# if that crops a slice of the room) so the view doesn't letterbox.
	var vp_size := Vector2(_sub_viewport.size)
	var scale: float = max(vp_size.x / room_rect.size.x, vp_size.y / room_rect.size.y)
	_cam.position = room_rect.position + room_rect.size * 0.5
	_cam.zoom = Vector2(scale, scale)
	_cam.make_current()
