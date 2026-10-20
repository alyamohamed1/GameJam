extends Area2D
# Walk-in hide spot (bathroom, closet). While the burglar's body overlaps,
# Game.burglar_hidden flips true. Dog detection logic in dog.gd respects
# the flag and never catches a hidden burglar. Only the host writes the
# flag so state stays unambiguous.

@export var hide_size: Vector2 = Vector2(40, 40)

@onready var _shape: CollisionShape2D = $Shape

func _ready() -> void:
	var rs := RectangleShape2D.new()
	rs.size = hide_size
	_shape.shape = rs
	body_entered.connect(_on_entered)
	body_exited.connect(_on_exited)

func _on_entered(body: Node) -> void:
	if not multiplayer.is_server():
		return
	if body.is_in_group("burglar"):
		Game.burglar_hidden = true

func _on_exited(body: Node) -> void:
	if not multiplayer.is_server():
		return
	if body.is_in_group("burglar"):
		Game.burglar_hidden = false
