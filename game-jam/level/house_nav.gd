class_name HouseNav extends RefCounted
# Room-graph pathfinder for the 6-room house (en-suite bathroom, closet
# is a hide-spot nook inside the bedroom with no door). Each edge stores
# the doorway center and the unit direction from room_a toward room_b
# (perpendicular to the wall). find_path emits two waypoints per crossing:
# the doorway center plus a point BUFFER px past the wall into the
# destination room, so a chasing dog clears wall collision before turning.

const BUFFER := 25.0

# Rough room rectangles — tight enough to classify a point to its room
# via room_at(). Walls themselves are placed in the editor; these rects
# only exist for nav lookups.
const ROOMS := {
	"kitchen":  Rect2(10, 10, 520, 370),
	"living":   Rect2(10, 395, 520, 500),
	"hallway":  Rect2(540, 10, 190, 890),
	"office":   Rect2(740, 10, 460, 345),
	"bathroom": Rect2(740, 370, 460, 160),
	"bedroom":  Rect2(540, 455, 660, 440),
}

# [room_a, room_b, doorway_center, direction_from_a_to_b (unit vector)]
const EDGES := [
	["kitchen", "living",   Vector2(361, 380), Vector2(0, 1)],
	["kitchen", "hallway",  Vector2(532, 318), Vector2(1, 0)],
	["living",  "hallway",  Vector2(533, 443), Vector2(1, 0)],
	["office",  "hallway",  Vector2(736, 216), Vector2(-1, 0)],
	["office",  "bathroom", Vector2(932, 362), Vector2(0, 1)],
	["bedroom", "hallway",  Vector2(660, 438), Vector2(-1, 0)],
]

static func room_at(pos: Vector2) -> String:
	for name in ROOMS:
		if ROOMS[name].has_point(pos):
			return name
	return ""

static func find_path(from: Vector2, to: Vector2) -> Array:
	var start := room_at(from)
	var end := room_at(to)
	if start == "" or end == "" or start == end:
		return [to]
	var rooms_path := _bfs(start, end)
	if rooms_path.is_empty():
		return [to]
	var waypoints: Array = []
	for i in range(rooms_path.size() - 1):
		var a: String = rooms_path[i]
		var b: String = rooms_path[i + 1]
		var edge := _edge(a, b)
		if edge.is_empty():
			continue
		var pos: Vector2 = edge.pos
		var dir: Vector2 = edge.dir if edge.a == a else -edge.dir
		waypoints.append(pos)
		waypoints.append(pos + dir * BUFFER)
	waypoints.append(to)
	return waypoints

static func _edge(a: String, b: String) -> Dictionary:
	for e in EDGES:
		if (e[0] == a and e[1] == b) or (e[0] == b and e[1] == a):
			return {"a": e[0], "pos": e[2], "dir": e[3]}
	return {}

static func _bfs(start: String, end: String) -> Array:
	var queue: Array = [[start]]
	var visited := {start: true}
	while not queue.is_empty():
		var path: Array = queue.pop_front()
		var last: String = path[-1]
		if last == end:
			return path
		for e in EDGES:
			if (e[0] == "bedroom" or e[1] == "bedroom") and not _bedroom_open():
				continue
			var neighbour := ""
			if e[0] == last and not visited.has(e[1]):
				neighbour = e[1]
			elif e[1] == last and not visited.has(e[0]):
				neighbour = e[0]
			if neighbour != "":
				visited[neighbour] = true
				var next := path.duplicate()
				next.append(neighbour)
				queue.append(next)
	return []

static func _bedroom_open() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return true
	var game := tree.root.get_node_or_null("Game")
	if game == null:
		return true
	return game.door_unlocked
