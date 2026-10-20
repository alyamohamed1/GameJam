extends CanvasLayer
# Fog of war for Player 1. Host-only: house.gd spawns this on the server
# side only, so the client never has fog nodes to render.
#
# follow_viewport_enabled tracks the host's Camera2D so Polygon2D rects
# placed at world coords stay anchored to their rooms as the camera
# scrolls. Monitors share world_2d but are rendered by separate
# SubViewports that have no fog CanvasLayer, so they stay clear.

const FOG_COLOR := Color(0, 0, 0, 0.7)

var _rects: Dictionary = {}
var _current_room: String = ""
var _burglar: Node2D = null

func _ready() -> void:
	layer = 15
	follow_viewport_enabled = true
	for room_name in HouseNav.ROOMS:
		var rect: Rect2 = HouseNav.ROOMS[room_name]
		var poly := Polygon2D.new()
		poly.name = String(room_name)
		poly.polygon = PackedVector2Array([
			rect.position,
			Vector2(rect.position.x + rect.size.x, rect.position.y),
			rect.position + rect.size,
			Vector2(rect.position.x, rect.position.y + rect.size.y),
		])
		poly.color = FOG_COLOR
		add_child(poly)
		_rects[String(room_name)] = poly

func _process(_delta: float) -> void:
	if _burglar == null:
		_burglar = get_tree().get_first_node_in_group("burglar")
		if _burglar == null:
			return
	var room := HouseNav.room_at(_burglar.global_position)
	if room == _current_room:
		return
	_current_room = room
	for name in _rects:
		var poly: Polygon2D = _rects[name]
		poly.visible = name != room
