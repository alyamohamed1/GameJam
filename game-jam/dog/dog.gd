extends CharacterBody2D
# Guard dog Biscuit. Host-authoritative: only host runs AI, position + state
# replicate to client via MultiplayerSynchronizer. Noise and distraction
# behaviours land in later sub-pieces.

enum State { PATROL, INVESTIGATE, DISTRACTED, ALERT }

const SIGHT_RANGE := 160.0
const SIGHT_HALF_ANGLE_DEG := 24.0
const ALERT_HOLD := 0.5  # seconds burglar must stay visible to be caught

@export var speed: float = 45.0
@export var waypoint_radius: float = 4.0

@export var patrol_points: PackedVector2Array = PackedVector2Array([
	Vector2(480, 135),
	Vector2(800, 135),
	Vector2(800, 405),
	Vector2(480, 405),
])

var state: int = State.PATROL
var _patrol_index: int = 0
var _facing: Vector2 = Vector2.RIGHT
var _alert_timer: float = 0.0
var _tracked_burglars: Array[Node] = []  # bodies currently inside sight Area2D

@onready var _sight: Area2D = $Sight
@onready var _sight_visual: Polygon2D = $Sight/Visual
@onready var _bubble: Label = $Bubble

func _ready() -> void:
	_bubble.hide()
	_sight.body_entered.connect(_on_sight_entered)
	_sight.body_exited.connect(_on_sight_exited)

func _physics_process(delta: float) -> void:
	var peer := multiplayer.multiplayer_peer
	if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	if not multiplayer.is_server():
		# Client still rotates the sight visual so facing looks right in the
		# monitor view; velocity isn't used here.
		_sight.rotation = _facing.angle()
		return
	if Game.modal_open or Game.phase == Game.Phase.FAIL:
		velocity = Vector2.ZERO
		return
	match state:
		State.PATROL:
			_tick_patrol()
		State.ALERT:
			_tick_alert(delta)
		_:
			velocity = Vector2.ZERO
	# Update facing from current velocity; keep last facing when idle.
	if velocity.length() > 1.0:
		_facing = velocity.normalized()
	_sight.rotation = _facing.angle()
	_check_sight(delta)

func _tick_patrol() -> void:
	if patrol_points.is_empty():
		velocity = Vector2.ZERO
		return
	var target := patrol_points[_patrol_index]
	var to_target := target - global_position
	if to_target.length() <= waypoint_radius:
		_patrol_index = (_patrol_index + 1) % patrol_points.size()
		return
	velocity = to_target.normalized() * speed
	move_and_slide()

func _tick_alert(_delta: float) -> void:
	# Freeze on spot while reacting. "!" bubble shows via _set_state.
	velocity = Vector2.ZERO

func _on_sight_entered(body: Node) -> void:
	if body.is_in_group("burglar") and body not in _tracked_burglars:
		_tracked_burglars.append(body)

func _on_sight_exited(body: Node) -> void:
	_tracked_burglars.erase(body)

func _check_sight(delta: float) -> void:
	var seen := false
	for body in _tracked_burglars:
		if _has_los(body):
			seen = true
			break
	if seen:
		if state != State.ALERT:
			_set_state(State.ALERT)
			_alert_timer = 0.0
		else:
			_alert_timer += delta
			if _alert_timer >= ALERT_HOLD:
				Game.set_phase(Game.Phase.FAIL)
	else:
		if state == State.ALERT:
			# Lost sight before the hold expired: back to patrol.
			_set_state(State.PATROL)

func _has_los(body: Node) -> bool:
	# Raycast from dog to burglar, hit anything on collision layer 1.
	# If the ray hits the burglar first (not a wall) we have line of sight.
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, body.global_position)
	query.exclude = [self]
	query.collision_mask = 1
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return true
	return hit.collider == body

func _set_state(s: int) -> void:
	state = s
	_bubble.visible = (s == State.ALERT)
