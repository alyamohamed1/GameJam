class_name HouseNav extends RefCounted
# Room-graph pathfinder for the 7-room house. Each edge stores the doorway
# center and the unit direction from room_a toward room_b (perpendicular
# to the wall). find_path emits two waypoints per crossing: the doorway
# center plus a point BUFFER px past the wall into the destination room,
# so a chasing dog clears wall collision before turning toward its next
# target.
#
# Closet rect sits inside Kitchen; it's listed first so room_at() returns
# "closet" for points inside the nook.

const BUFFER := 25.0

const ROOMS := {
	"closet":   Rect2(320, 0, 80, 80),
	"kitchen":  Rect2(0, 0, 400, 400),
	"living":   Rect2(0, 405, 400, 495),
	"hallway":  Rect2(410, 0, 340, 900),
	"office":   Rect2(760, 0, 440, 345),
	"bathroom": Rect2(760, 355, 440, 245),
	"bedroom":  Rect2(760, 610, 440, 290),
}

# [room_a, room_b, doorway_center, direction_from_a_to_b (unit vector)]
const EDGES := [
	["kitchen", "closet",   Vector2(360, 80),   Vector2(0, -1)],
	["kitchen", "living",   Vector2(130, 400),  Vector2(0, 1)],
	["kitchen", "hallway",  Vector2(400, 200),  Vector2(1, 0)],
	["living",  "hallway",  Vector2(400, 650),  Vector2(1, 0)],
	["office",  "hallway",  Vector2(750, 180),  Vector2(-1, 0)],
	["office",  "bathroom", Vector2(1000, 350), Vector2(0, 1)],
	["bedroom", "hallway",  Vector2(750, 750),  Vector2(-1, 0)],
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
