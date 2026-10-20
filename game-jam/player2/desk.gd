extends Control
# Player 2 desk. One SubViewport that shares the house's world_2d, with
# a Camera2D centered on the burglar spawn. Stage 0: single monitor only.

@onready var sub_viewport: SubViewport = $Monitor/SubViewport
@onready var cam: Camera2D = $Monitor/SubViewport/Camera2D

func _ready() -> void:
	sub_viewport.world_2d = get_tree().root.world_2d
	cam.make_current()
