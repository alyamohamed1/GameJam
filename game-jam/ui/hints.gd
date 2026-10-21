extends Node
# Global hint banner. Shows a short line at the bottom of the screen to
# guide the current player through the next step. Call via:
#   Hints.show("find the laptop")             # both peers
#   Hints.show_host("...")                     # only host (P1)
#   Hints.show_client("...")                   # only client (P2)
# Hints auto-hide after `duration` seconds (0 = persist until replaced).

const DEFAULT_DURATION := 6.0

var _layer: CanvasLayer
var _label: Label
var _timer: Timer

func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 40
	add_child(_layer)
	var root := Control.new()
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(root)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 1.0
	panel.anchor_right = 0.5
	panel.anchor_bottom = 1.0
	panel.offset_left = -180
	panel.offset_top = -36
	panel.offset_right = 180
	panel.offset_bottom = -8
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.modulate = Color(1, 1, 1, 0.92)
	root.add_child(panel)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 11)
	_label.add_theme_color_override("font_color", Color(1, 0.95, 0.6, 1))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	_label.add_theme_constant_override("outline_size", 4)
	panel.add_child(_label)
	_layer.visible = false
	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(clear)

func show(text: String, duration: float = DEFAULT_DURATION) -> void:
	_label.text = text
	_layer.visible = true
	_timer.stop()
	if duration > 0.0:
		_timer.start(duration)

func show_host(text: String, duration: float = DEFAULT_DURATION) -> void:
	if _is_host():
		show(text, duration)

func show_client(text: String, duration: float = DEFAULT_DURATION) -> void:
	if not _is_host():
		show(text, duration)

func clear() -> void:
	_layer.visible = false

func _is_host() -> bool:
	var peer := multiplayer.multiplayer_peer
	if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return true  # single-player fallback
	return multiplayer.is_server()
