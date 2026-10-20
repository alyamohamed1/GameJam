extends CanvasLayer
# Player 2 desk. CanvasLayer so this UI is NOT part of world_2d (otherwise a
# SubViewport sharing world_2d would render the desk inside its own monitor).
# Hosts 5 fixed-camera monitors + the Feeder button. Monitors flip from
# NO SIGNAL to live when phase becomes POST_USB.

@onready var feeder_btn: Button = $Root/Devices/HBox/FeederBtn
@onready var phase_label: Label = $Root/Devices/HBox/PhaseLabel
@onready var monitors_root: Node = $Root/Monitors

func _ready() -> void:
	feeder_btn.pressed.connect(Game.request_feeder)
	Game.phase_changed.connect(_on_phase_changed)
	_apply_phase(Game.phase)

func _process(_delta: float) -> void:
	if Game.feeder_cooldown > 0.0:
		feeder_btn.disabled = true
		feeder_btn.text = "Feeder (%ds)" % int(ceil(Game.feeder_cooldown))
	else:
		feeder_btn.disabled = false
		feeder_btn.text = "Trigger Feeder"

func _on_phase_changed(p: int) -> void:
	_apply_phase(p)

func _apply_phase(p: int) -> void:
	phase_label.text = "Phase: %s" % _phase_name(p)
	# Pre-USB: only always_live monitors (kitchen feeder cam) show feed.
	# Post-USB onward: all monitors live.
	var all_live := p >= Game.Phase.POST_USB
	for m in monitors_root.get_children():
		if m.has_method("set_live"):
			m.set_live(all_live or m.always_live)

func _phase_name(p: int) -> String:
	match p:
		Game.Phase.LOBBY: return "LOBBY"
		Game.Phase.PRE_USB: return "PRE_USB"
		Game.Phase.POST_USB: return "POST_USB"
		Game.Phase.BLACKOUT: return "BLACKOUT"
		Game.Phase.VICTORY: return "VICTORY"
		Game.Phase.FAIL: return "FAIL"
		_: return "?"
