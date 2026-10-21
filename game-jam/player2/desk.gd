extends CanvasLayer
# Player 2 desk. CanvasLayer so this UI is NOT part of world_2d. Hosts the
# 5 fixed-camera monitors, the home computer cipher panel, the Feeder
# button, and the phase readout. Everything client-side: no RPCs from here
# except Game.request_feeder.

const FULLSCREEN_SCENE := preload("res://player2/monitor_fullscreen.tscn")

@onready var feeder_btn: Button = $Root/Devices/VBox/FeederBtn
@onready var phase_label: Label = $Root/Devices/VBox/PhaseLabel
@onready var monitors_root: Node = $Root/Monitors
@onready var hc_locked: Control = $Root/HomeComputer/LockedOverlay
@onready var hc_shift_label: Label = $Root/HomeComputer/VBox/ShiftRow/ShiftLabel
@onready var hc_decoded: Label = $Root/HomeComputer/VBox/Decoded
@onready var hc_minus: Button = $Root/HomeComputer/VBox/ShiftRow/Minus
@onready var hc_plus: Button = $Root/HomeComputer/VBox/ShiftRow/Plus
@onready var hc_cipher_edit: LineEdit = $Root/HomeComputer/VBox/CipherEdit

# Transparent screen windows in P2_Monitors.png (image px). Monitors are laid
# out from these at runtime so they track the background's cover-scaling at
# any window aspect.
const BG_SIZE := Vector2(1536, 1024)
const MONITOR_HOLES := {
	"Kitchen": Rect2(295, 91, 411, 222),
	"Living": Rect2(784, 91, 379, 221),
	"Office": Rect2(295, 390, 411, 217),
	"Bedroom": Rect2(784, 390, 379, 217),
}

var _shift: int = 0
var _decrypt_played: bool = false

func _ready() -> void:
	feeder_btn.pressed.connect(func() -> void:
		SFX.play("p2_click")
		Game.request_feeder())
	hc_minus.pressed.connect(func() -> void:
		SFX.play("p2_click")
		_change_shift(-1))
	hc_plus.pressed.connect(func() -> void:
		SFX.play("p2_click")
		_change_shift(1))
	hc_cipher_edit.text_changed.connect(func(_t: String) -> void: _update_cipher_display())
	Game.phase_changed.connect(_on_phase_changed)
	for m in monitors_root.get_children():
		if m.has_signal("clicked"):
			m.clicked.connect(_on_monitor_clicked)
	_update_cipher_display()
	_apply_phase(Game.phase)
	$Root.resized.connect(_layout_monitors)
	_layout_monitors()

func _layout_monitors() -> void:
	var view: Vector2 = $Root.size
	var s: float = max(view.x / BG_SIZE.x, view.y / BG_SIZE.y)
	var origin := (view - BG_SIZE * s) * 0.5
	monitors_root.position = Vector2.ZERO
	for n in MONITOR_HOLES:
		var m: Control = monitors_root.get_node_or_null(n)
		if m == null:
			continue
		var r: Rect2 = MONITOR_HOLES[n]
		var sc := Vector2(r.size.x * s / 160.0, r.size.y * s / 90.0)
		m.size = Vector2(160, 100)
		m.scale = sc
		# Screen area starts 10px below the monitor origin (title strip).
		m.position = origin + r.position * s - Vector2(0, 10.0 * sc.y)

func _on_monitor_clicked(monitor: Node) -> void:
	# Ignore clicks on NO SIGNAL monitors.
	if not monitor.live:
		return
	SFX.play("p2_mouse", -6.0)
	var fs: CanvasLayer = FULLSCREEN_SCENE.instantiate()
	fs.room_rect = monitor.room_rect
	fs.room_label = monitor.room_label
	add_child(fs)

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
	# Decrypt whatever P2 typed by shifting forward (the cipher in this
	# game was produced by shifting plaintext backward).
	var decoded := Cipher.shift(hc_cipher_edit.text, _shift)
	hc_decoded.text = decoded
	# Chime when the decoded text contains the plaintext safe-code words.
	# One-shot per unique match so it doesn't spam on every keystroke.
	if decoded.to_lower().replace(" ", "") == "onetwosix":
		if not _decrypt_played:
			SFX.play("p2_decrypt")
			_decrypt_played = true
	else:
		_decrypt_played = false

func _on_phase_changed(p: int) -> void:
	_apply_phase(p)

func _apply_phase(p: int) -> void:
	phase_label.text = "Phase: %s" % _phase_name(p)
	var all_live := p >= Game.Phase.POST_USB
	var night_vision := p >= Game.Phase.BLACKOUT
	for m in monitors_root.get_children():
		if m.has_method("set_live"):
			m.set_live(all_live or m.always_live)
		# Green CRT tint on all monitors once blackout starts.
		m.modulate = Color(0.4, 1.0, 0.5) if night_vision else Color(1, 1, 1)
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
