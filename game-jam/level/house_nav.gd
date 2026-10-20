class_name HouseNav extends RefCounted
# Minimal room-graph pathfinder for the Stage 1 house. The house is a fixed
# 2x3 grid; rooms connect to orthogonal neighbours through known doorway
# centers. find_path returns a sequence of Vector2 waypoints that walks
# from a point in one room to a point in another, always passing through
# the doorway centers (so straight-line movement between waypoints never
# crosses a wall).

const ROOMS := {
	"kitchen":  Rect2(0, 0, 320, 270),
	"living":   Rect2(320, 0, 320, 270),
	"bedroom":  Rect2(640, 0, 320, 270),
	"entrance": Rect2(0, 270, 320, 270),
	"hallway":  Rect2(320, 270, 320, 270),
	"empty":    Rect2(640, 270, 320, 270),
}

# [room_a, room_b, doorway_center]
const EDGES := [
	["kitchen", "living",   Vector2(320, 135)],
	["living",  "bedroom",  Vector2(640, 135)],
	["entrance","hallway",  Vector2(320, 405)],
	["hallway", "empty",    Vector2(640, 405)],
	["kitchen", "entrance", Vector2(160, 270)],
	["living",  "hallway",  Vector2(480, 270)],
	["bedroom", "empty",    Vector2(800, 270)],
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
		waypoints.append(_doorway(rooms_path[i], rooms_path[i + 1]))
	waypoints.append(to)
	return waypoints

static func _doorway(a: String, b: String) -> Vector2:
	for e in EDGES:
		if (e[0] == a and e[1] == b) or (e[0] == b and e[1] == a):
			return e[2]
	return Vector2.ZERO

static func _bfs(start: String, end: String) -> Array:
	var queue: Array = [[start]]
	var visited := {start: true}
	while not queue.is_empty():
		var path: Array = queue.pop_front()
		var last: String = path[-1]
		if last == end:
			return path
		for e in EDGES:
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
