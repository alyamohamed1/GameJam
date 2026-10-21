extends CharacterBody2D
# Guard dog Biscuit. Host-authoritative; position + state replicate.
#
# States:
#   PATROL      - walking a loop through every room via HouseNav
#   INVESTIGATE - heard noise, going to that spot
#   DISTRACTED  - eating at the feeder; sight off
#   CHASE       - burglar is in the same room (and not hidden); chasing
#   SEARCH      - lost burglar (hidden or left room); roaming current room
#
# Catch is contact-based: distance to burglar <= CATCH_DIST while chasing
# triggers Game.set_phase(FAIL). No sight cone.

enum State { PATROL, INVESTIGATE, DISTRACTED, CHASE, SEARCH, ALERT }

const PATROL_SPEED := 40.0
const CHASE_SPEED := 110.0

const WAYPOINT_RADIUS := 6.0
const CATCH_DIST := 20.0

const NOTICE_DELAY := 0.3           # same-room time before CHASE kicks in
const HEARING_RANGE := 160.0
const INVESTIGATE_SNIFF := 2.0
const INVESTIGATE_TIMEOUT := 6.0
const CHASE_REPATH_INTERVAL := 0.25 # how often to recompute nav to burglar
const CHASE_STUCK_TIME := 2.0       # if the dog hasn't moved for this long during chase, force a repath
const CHASE_STUCK_MIN_DIST := 2.0   # per-tick distance under which we count as 'stuck'
const SEARCH_DURATION := 5.0        # how long to roam a room after losing scent
const SEARCH_WAYPOINT_HOLD := 1.0   # how long between picking a new wander point
const TURN_SPEED := 6.0

@export var patrol_rooms: PackedStringArray = PackedStringArray([
	"living", "hallway", "kitchen", "hallway", "office", "bathroom",
	"office", "hallway", "bedroom",
])

var state: int = State.PATROL
var _facing: Vector2 = Vector2.RIGHT
var _path: Array = []
var _patrol_index: int = 0

var _notice_timer: float = 0.0       # same-room accumulator before CHASE
var _investigate_timer: float = 0.0
var _sniff_timer: float = 0.0
var _distract_timer: float = 0.0
var _eat_timer: float = 0.0
var _chase_repath_timer: float = 0.0
var _chase_stuck_timer: float = 0.0
var _chase_last_pos: Vector2 = Vector2.ZERO
var _search_timer: float = 0.0
var _search_wander_timer: float = 0.0

var _burglar: Node2D = null

@onready var _sight: Area2D = $Sight
@onready var _bubble: Label = $Bubble

func _ready() -> void:
	# Sight cone is retired. Keep the node around (dog.tscn hasn't been
	# changed) but silence it.
	if _sight:
		_sight.monitoring = false
		_sight.visible = false
	_bubble.hide()
	Game.noise_at.connect(_on_noise)
	# Hide the dog sprite from Player 1's main viewport. The client's
	# monitors share world_2d but render via separate SubViewports, which
	# don't inherit this modulate change because the Sprite ColorRect lives
	# in world_2d; so instead of modulate, we clear the color on host only.
	# Debug collider boxes always off for the dog (P1 shouldn't tell where
	# the dog is from an outline). Visibility is toggled every frame based
	# on whether the burglar is in the same room.
	for s in find_children("", "CollisionShape2D", true, false):
		s.debug_color = Color(0, 0, 0, 0)

func _physics_process(delta: float) -> void:
	var peer := multiplayer.multiplayer_peer
	if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	if not multiplayer.is_server():
		return
	if Game.modal_open or Game.phase == Game.Phase.FAIL or Game.phase == Game.Phase.VICTORY:
		velocity = Vector2.ZERO
		return
	if _burglar == null:
		_burglar = get_tree().get_first_node_in_group("burglar")
	_update_visibility()
	_detect_burglar(delta)
	match state:
		State.PATROL:
			_tick_patrol(delta)
		State.INVESTIGATE:
			_tick_investigate(delta)
		State.DISTRACTED:
			_tick_distracted(delta)
		State.CHASE:
			_tick_chase(delta)
		State.SEARCH:
			_tick_search(delta)
		_:
			velocity = Vector2.ZERO
	if velocity.length() > 1.0:
		var desired := velocity.normalized()
		var step := TURN_SPEED * delta
		_facing = _facing.rotated(clamp(_facing.angle_to(desired), -step, step)).normalized()

# ---- Visibility ----

# Host only. P1 only sees the dog when they're in the same room; otherwise
# the sprite is fully transparent so P2 has to call out dog positions.
func _update_visibility() -> void:
	var sprite := get_node_or_null("Sprite")
	if sprite == null:
		return
	if _burglar == null:
		sprite.modulate.a = 0.0
		return
	var same_room := HouseNav.room_at(global_position) == HouseNav.room_at(_burglar.global_position)
	sprite.modulate.a = 1.0 if same_room else 0.0

# ---- Detection ----

func _detect_burglar(delta: float) -> void:
	if _burglar == null:
		return
	if state == State.DISTRACTED:
		return
	var same_room := HouseNav.room_at(global_position) == HouseNav.room_at(_burglar.global_position)
	var visible := same_room and not Game.burglar_hidden
	if visible:
		_notice_timer += delta
		if _notice_timer >= NOTICE_DELAY and state != State.CHASE:
			_begin_chase()
	else:
		_notice_timer = 0.0
		if state == State.CHASE:
			_begin_search()

# ---- Catching ----

func _check_catch() -> void:
	if _burglar == null:
		return
	if Game.burglar_hidden:
		return
	if global_position.distance_to(_burglar.global_position) <= CATCH_DIST:
		Game.set_phase(Game.Phase.FAIL)

# ---- States ----

func _tick_patrol(_delta: float) -> void:
	if _path.is_empty():
		_next_patrol_destination()
	if _path.is_empty():
		velocity = Vector2.ZERO
		return
	_walk_path(PATROL_SPEED)

func _next_patrol_destination() -> void:
	if patrol_rooms.is_empty():
		return
	# Try up to patrol_rooms.size() times so we skip over blocked rooms
	# (e.g., Bedroom while its door is still locked) without blocking.
	for _i in range(patrol_rooms.size()):
		var room := patrol_rooms[_patrol_index]
		_patrol_index = (_patrol_index + 1) % patrol_rooms.size()
		if room == "bedroom" and not Game.door_unlocked:
			continue
		var rect: Rect2 = HouseNav.ROOMS.get(room, Rect2())
		if rect.size == Vector2.ZERO:
			continue
		var target: Vector2 = rect.position + rect.size * 0.5
		_path = HouseNav.find_path(global_position, target)
		return

func _tick_investigate(delta: float) -> void:
	_investigate_timer += delta
	if _investigate_timer >= INVESTIGATE_TIMEOUT:
		_set_state(State.PATROL)
		_path.clear()
		return
	if _path.is_empty():
		velocity = Vector2.ZERO
		_sniff_timer += delta
		if _sniff_timer >= INVESTIGATE_SNIFF:
			_set_state(State.PATROL)
		return
	_walk_path(PATROL_SPEED)

func _tick_distracted(delta: float) -> void:
	_distract_timer += delta
	if not _path.is_empty() and _distract_timer < INVESTIGATE_TIMEOUT:
		_walk_path(PATROL_SPEED)
		return
	velocity = Vector2.ZERO
	_eat_timer += delta
	if _eat_timer >= Game.FEEDER_EAT_TIME:
		_sight.monitoring = false  # stays off; the cone is retired
		_set_state(State.PATROL)
		_path.clear()
		SFX.stop_loop("dog_eat")

func _tick_chase(delta: float) -> void:
	# Stuck detection: if the dog hasn't moved more than CHASE_STUCK_MIN_DIST
	# over CHASE_STUCK_TIME seconds, force a repath so furniture doesn't
	# permanently trap it on a corner.
	if global_position.distance_to(_chase_last_pos) < CHASE_STUCK_MIN_DIST:
		_chase_stuck_timer += delta
	else:
		_chase_stuck_timer = 0.0
	_chase_last_pos = global_position
	if _chase_stuck_timer >= CHASE_STUCK_TIME:
		_chase_stuck_timer = 0.0
		_chase_repath_timer = 0.0
		_path.clear()
	_chase_repath_timer -= delta
	if _chase_repath_timer <= 0.0 or _path.is_empty():
		_chase_repath_timer = CHASE_REPATH_INTERVAL
		if _burglar:
			_path = HouseNav.find_path(global_position, _burglar.global_position)
	if _path.is_empty():
		velocity = Vector2.ZERO
		return
	_walk_path(CHASE_SPEED)
	_check_catch()

func _tick_search(delta: float) -> void:
	_search_timer += delta
	if _search_timer >= SEARCH_DURATION:
		_set_state(State.PATROL)
		_path.clear()
		return
	_search_wander_timer -= delta
	if _search_wander_timer <= 0.0 or _path.is_empty():
		_search_wander_timer = SEARCH_WAYPOINT_HOLD
		_path = [_random_point_in_current_room()]
	_walk_path(PATROL_SPEED)

# ---- Transitions ----

func _begin_chase() -> void:
	_set_state(State.CHASE)
	_chase_repath_timer = 0.0
	_chase_stuck_timer = 0.0
	_chase_last_pos = global_position
	_path.clear()
	SFX.play("dog_bark")
	SFX.loop("dog_growl", "dog_growl", -6.0)

func _begin_search() -> void:
	_set_state(State.SEARCH)
	_search_timer = 0.0
	_search_wander_timer = 0.0
	_path.clear()
	SFX.stop_loop("dog_growl")
	SFX.play("dog_sniff")

# ---- Shared helpers ----

func _walk_path(speed: float) -> void:
	if _path.is_empty():
		velocity = Vector2.ZERO
		return
	var target: Vector2 = _path[0]
	var to_target := target - global_position
	if to_target.length() <= WAYPOINT_RADIUS:
		_path.pop_front()
		return
	velocity = to_target.normalized() * speed
	move_and_slide()

func _random_point_in_current_room() -> Vector2:
	var room := HouseNav.room_at(global_position)
	var rect: Rect2 = HouseNav.ROOMS.get(room, Rect2())
	if rect.size == Vector2.ZERO:
		return global_position
	# Inset so the point is well inside the room, away from walls.
	var inset := 30.0
	var min_x := rect.position.x + inset
	var max_x := rect.end.x - inset
	var min_y := rect.position.y + inset
	var max_y := rect.end.y - inset
	return Vector2(randf_range(min_x, max_x), randf_range(min_y, max_y))

func _set_state(s: int) -> void:
	state = s
	# Bubble is retained for a possible future UI cue.
	_bubble.visible = false

# ---- Public (host) ----

func distract_at(pos: Vector2) -> void:
	if not multiplayer.is_server():
		return
	if state == State.CHASE:
		return  # don't abandon a chase for food
	_path = HouseNav.find_path(global_position, pos)
	_distract_timer = 0.0
	_eat_timer = 0.0
	_set_state(State.DISTRACTED)
	SFX.stop_loop("dog_growl")
	SFX.play("dog_kibble")
	SFX.loop("dog_eat", "dog_eat", -8.0)

# ---- Signals ----

func _on_noise(pos: Vector2) -> void:
	if not multiplayer.is_server():
		return
	if state == State.CHASE or state == State.DISTRACTED or state == State.SEARCH:
		return
	if global_position.distance_to(pos) > HEARING_RANGE:
		return
	# If burglar is in the same room already, detection in _detect_burglar
	# will trigger CHASE on its own next frame.
	_path = HouseNav.find_path(global_position, pos)
	_investigate_timer = 0.0
	_sniff_timer = 0.0
	_set_state(State.INVESTIGATE)
