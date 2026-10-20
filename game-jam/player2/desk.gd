extends CanvasLayer
# Player 2 desk. CanvasLayer so this UI is NOT part of world_2d — otherwise
# a SubViewport sharing world_2d would render the desk inside its own monitor
# (recursion). Each monitor is a SubViewport pointed at a fixed Camera2D in
# a specific room. Stage 1: one monitor (kitchen); add 4 more later.

@onready var sub_viewport: SubViewport = $Root/Monitor/SubViewport
@onready var cam: Camera2D = $Root/Monitor/SubViewport/Camera2D

func _ready() -> void:
	sub_viewport.world_2d = get_tree().root.world_2d
	cam.make_current()
