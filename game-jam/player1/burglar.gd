extends CharacterBody2D
# Burglar. Host is authority: only host reads input and moves. Position
# syncs to client via MultiplayerSynchronizer sibling node. Also tracks the
# most-recently-entered Interactable zone and triggers it on interact input.

@export var speed: float = 60.0
@export var run_mult: float = 1.8

const NOISE_INTERVAL := 0.25
const STEP_INTERVAL_WALK := 0.42
const STEP_INTERVAL_RUN := 0.25

@onready var _sprite: AnimatedSprite2D = $Sprite

var _current_zone: Node = null
var _noise_cooldown: float = 0.0
var _step_timer: float = 0.0
var _last_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	_last_pos = global_position
	# Client-only highlight ring under the cat so P2 can spot the burglar
	# on their monitors without seeing a glowing circle in P1's main view.
	# Lives in world_2d but added only on the client, so host never renders it.
	call_deferred("_add_client_highlight")

func _add_client_highlight() -> void:
	var peer := multiplayer.multiplayer_peer
	if peer == null:
		return
	if multiplayer.is_server():
		return
	if has_node("P2Highlight"):
		return
	var hl := Sprite2D.new()
	hl.name = "P2Highlight"
	hl.z_index = -1
	hl.modulate = Color(1.0, 0.95, 0.3, 1.0)
	hl.texture = _make_glow_tex(Color(1, 1, 0.5, 1), Color(1, 0.85, 0.2, 0))
	hl.scale = Vector2(0.9, 0.9)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	hl.material = mat
	add_child(hl)

func _make_glow_tex(center: Color, edge: Color) -> Texture2D:
	var grad := Gradient.new()
	grad.add_point(0.0, center)
	grad.add_point(0.5, Color(center.r, center.g, center.b, 0.6))
	grad.add_point(1.0, edge)
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	return tex

func _physics_process(delta: float) -> void:
	# Guard: scene may load one frame before the ENet peer is fully active.
	var peer := multiplayer.multiplayer_peer
	if peer == null or peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	if multiplayer.is_server():
		_tick_host(delta)
	_tick_anim()

func _tick_host(delta: float) -> void:
	if Game.modal_open:
		velocity = Vector2.ZERO
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var running := Input.is_action_pressed("run")
	var s := speed
	if running:
		s *= run_mult
	velocity = dir * s
	move_and_slide()
	_noise_cooldown = max(0.0, _noise_cooldown - delta)
	if running and velocity.length() > 1.0 and _noise_cooldown == 0.0:
		Game.noise_at.emit(global_position)
		_noise_cooldown = NOISE_INTERVAL
	_step_timer -= delta
	var active := Game.phase == Game.Phase.PRE_USB \
		or Game.phase == Game.Phase.POST_USB \
		or Game.phase == Game.Phase.BLACKOUT
	if active and velocity.length() > 1.0:
		if _step_timer <= 0.0:
			if running:
				SFX.play_channel("step", "run", -6.0)
				_step_timer = STEP_INTERVAL_RUN
			else:
				SFX.play_random_step()
				_step_timer = STEP_INTERVAL_WALK
	else:
		_step_timer = 0.0
	if Input.is_action_just_pressed("interact") and _current_zone != null:
		_current_zone.trigger(self)

func _tick_anim() -> void:
	if _sprite == null:
		return
	# Derive movement vector locally so client animates from position delta
	# without needing replicated velocity.
	var move_vec: Vector2
	if multiplayer.is_server():
		move_vec = velocity
	else:
		move_vec = global_position - _last_pos
	_last_pos = global_position
	var anim: StringName = &"idle"
	if move_vec.length() >= 2.0:
		# Dominant axis so diagonals don't flicker.
		if absf(move_vec.x) > absf(move_vec.y):
			anim = &"walk_right" if move_vec.x > 0.0 else &"walk_left"
		else:
			anim = &"walk_down" if move_vec.y > 0.0 else &"walk_up"
	if _sprite.animation != anim:
		_sprite.play(anim)

func set_current_zone(z: Node) -> void:
	_current_zone = z

func clear_current_zone(z: Node) -> void:
	if _current_zone == z:
		_current_zone = null
