extends CanvasLayer
# Player 2 desk. CanvasLayer so this UI is NOT part of world_2d. Hosts the
# 5 fixed-camera monitors, the home computer cipher panel, the Feeder
# button, and the phase readout. Everything client-side: no RPCs from here
# except Game.request_feeder.

const CIPHERTEXT := "VHYHQ WZR QLQH IRXU"

@onready var feeder_btn: Button = $Root/Devices/HBox/FeederBtn
@onready var phase_label: Label = $Root/Devices/HBox/PhaseLabel
@onready var monitors_root: Node = $Root/Monitors
@onready var hc_locked: Control = $Root/HomeComputer/LockedOverlay
@onready var hc_shift_label: Label = $Root/HomeComputer/VBox/ShiftRow/ShiftLabel
@onready var hc_decoded: Label = $Root/HomeComputer/VBox/Decoded
@onready var hc_minus: Button = $Root/HomeComputer/VBox/ShiftRow/Minus
@onready var hc_plus: Button = $Root/HomeComputer/VBox/ShiftRow/Plus

var _shift: int = 0

func _ready() -> void:
	feeder_btn.pressed.connect(Game.request_feeder)
	hc_minus.pressed.connect(func() -> void: _change_shift(-1))
	hc_plus.pressed.connect(func() -> void: _change_shift(1))
	Game.phase_changed.connect(_on_phase_changed)
	_update_cipher_display()
	_apply_phase(Game.phase)

func _process(_delta: float) -> void:
	if Game.feeder_cooldown > 0.0:
		feeder_btn.disabled = true
		feeder_btn.text = "Feeder (%ds)" % int(ceil(Game.feeder_cooldown))
	else:
		feeder_btn.disabled = false
		feeder_btn.text = "Trigger Feeder"

func _change_shift(delta: int) -> void:
	_shift = ((_shift + delta) % 26 + 26) % 26
	_update_cipher_display()

func _update_cipher_display() -> void:
	hc_shift_label.text = "shift %d" % _shift
	# Decrypt by shifting backward by the chosen amount.
	hc_decoded.text = Cipher.shift(CIPHERTEXT, -_shift)

func _on_phase_changed(p: int) -> void:
	_apply_phase(p)

func _apply_phase(p: int) -> void:
	phase_label.text = "Phase: %s" % _phase_name(p)
	var all_live := p >= Game.Phase.POST_USB
	for m in monitors_root.get_children():
		if m.has_method("set_live"):
			m.set_live(all_live or m.always_live)
	hc_locked.visible = not all_live

func _phase_name(p: int) -> String:
	match p:
		Game.Phase.LOBBY: return "LOBBY"
		Game.Phase.PRE_USB: return "PRE_USB"
		Game.Phase.POST_USB: return "POST_USB"
		Game.Phase.BLACKOUT: return "BLACKOUT"
		Game.Phase.VICTORY: return "VICTORY"
		Game.Phase.FAIL: return "FAIL"
		_: return "?"
