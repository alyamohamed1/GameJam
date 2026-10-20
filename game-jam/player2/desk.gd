extends CanvasLayer
# Player 2 desk. CanvasLayer so this UI is NOT part of world_2d (otherwise a
# SubViewport sharing world_2d would render the desk inside its own monitor).
# Each monitor is a SubViewport pointed at a fixed Camera2D in a specific
# room. Devices panel below the monitor hosts the Feeder button (vacuum
# comes in Stage 2).

@onready var sub_viewport: SubViewport = $Root/Monitor/SubViewport
@onready var cam: Camera2D = $Root/Monitor/SubViewport/Camera2D
@onready var feeder_btn: Button = $Root/Devices/VBox/FeederBtn

func _ready() -> void:
	sub_viewport.world_2d = get_tree().root.world_2d
	cam.make_current()
	feeder_btn.pressed.connect(Game.request_feeder)

func _process(_delta: float) -> void:
	if Game.feeder_cooldown > 0.0:
		feeder_btn.disabled = true
		feeder_btn.text = "Feeder (%ds)" % int(ceil(Game.feeder_cooldown))
	else:
		feeder_btn.disabled = false
		feeder_btn.text = "Trigger Feeder"
