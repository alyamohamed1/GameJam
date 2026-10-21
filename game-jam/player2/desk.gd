extends CanvasLayer
# Player 2 desk. CanvasLayer so this UI is NOT part of world_2d. Hosts the
# 5 fixed-camera monitors, the home computer cipher panel, the Feeder
# button, and the phase readout. Everything client-side: no RPCs from here
# except Game.request_feeder.

const FULLSCREEN_SCENE := preload("res://player2/monitor_fullscreen.tscn")
const P2_LAPTOP_SCENE := preload("res://player2/p2_laptop_fullscreen.tscn")
const MODAL_PASSWORD := preload("res://ui/modal_password.tscn")
const HOME_PW := "Schopenhaeur2025"
const GLITCH_TEX := preload("res://art/glitchedoutmonitorsdesk.png")
const BETRAYED_TEX := preload("res://art/SystemBetrayedYouMessage.png")

@onready var feeder_btn: Button = $Root/Devices/VBox/FeederBtn
@onready var phase_label: Label = $Root/Devices/VBox/PhaseLabel
@onready var monitors_root: Node = $Root/Monitors
@onready var hc_locked: Control = $Root/HomeComputer/LockedOverlay
@onready var laptop_open_btn: Button = $Root/Laptop/OpenBtn
@onready var laptop_locked: Control = $Root/Laptop/LockedOverlay
@onready var hc_shift_label: Label = $Root/HomeComputer/VBox/ShiftRow/ShiftLabel
@onready var hc_decoded: Label = $Root/HomeComputer/VBox/Decoded
@onready var hc_minus: Button = $Root/HomeComputer/VBox/ShiftRow/Minus
@onready var hc_plus: Button = $Root/HomeComputer/VBox/ShiftRow/Plus
@onready var hc_cipher_edit: LineEdit = $Root/HomeComputer/VBox/CipherEdit

var _shift: int = 0
var _decrypt_played: bool = false
var _glitch_overlay: TextureRect = null
var _betrayed_popup: TextureRect = null

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
	laptop_open_btn.pressed.connect(_on_laptop_open)
	Game.phase_changed.connect(_on_phase_changed)
	for m in monitors_root.get_children():
		if m.has_signal("clicked"):
			m.clicked.connect(_on_monitor_clicked)
	_update_cipher_display()
	_apply_phase(Game.phase)

func _on_laptop_open() -> void:
	SFX.play("p2_click")
	var lf: CanvasLayer = P2_LAPTOP_SCENE.instantiate()
	add_child(lf)

# ---- Blackout glitch mechanic ----

func _begin_glitch() -> void:
	# Full-screen glitched desk art overlays everything so monitors "disappear".
	monitors_root.visible = false
	if _glitch_overlay == null:
		_glitch_overlay = TextureRect.new()
		_glitch_overlay.texture = GLITCH_TEX
		_glitch_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_glitch_overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_glitch_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		$Root.add_child(_glitch_overlay)
	_glitch_overlay.visible = true
	SFX.play("power_off")
	_show_betrayed_popup()

func _show_betrayed_popup() -> void:
	if _betrayed_popup == null:
		_betrayed_popup = TextureRect.new()
		_betrayed_popup.texture = BETRAYED_TEX
		_betrayed_popup.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_betrayed_popup.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		_betrayed_popup.set_anchors_preset(Control.PRESET_CENTER)
		_betrayed_popup.offset_left = -180
		_betrayed_popup.offset_top = -80
		_betrayed_popup.offset_right = 180
		_betrayed_popup.offset_bottom = 80
		$Root.add_child(_betrayed_popup)
	_betrayed_popup.visible = true
	get_tree().create_timer(2.0).timeout.connect(func() -> void:
		if _betrayed_popup:
			_betrayed_popup.visible = false
		_prompt_home_password())

func _prompt_home_password() -> void:
	var modal: CanvasLayer = MODAL_PASSWORD.instantiate()
	add_child(modal)
	modal.setup("HOME PASSWORD")
	modal.submitted.connect(func(text: String) -> void:
		if text.strip_edges() == HOME_PW:
			SFX.play("password_ok")
			modal.close()
			_on_home_password_ok()
		else:
			SFX.play("password_wrong")
			modal.set_status("Access denied. Hint: where the milk lives."))

func _on_home_password_ok() -> void:
	# Restore monitors + nightvision mode.
	if _glitch_overlay:
		_glitch_overlay.visible = false
	monitors_root.visible = true

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
		m.modulate = Color(0.4, 1.0, 0.5) if night_vision else Color(1, 1, 1)
	hc_locked.visible = not all_live
	laptop_locked.visible = not all_live
	laptop_open_btn.disabled = not all_live
	if p == Game.Phase.BLACKOUT:
		_begin_glitch()

func _phase_name(p: int) -> String:
	match p:
		Game.Phase.LOBBY: return "LOBBY"
		Game.Phase.PRE_USB: return "PRE_USB"
		Game.Phase.POST_USB: return "POST_USB"
		Game.Phase.BLACKOUT: return "BLACKOUT"
		Game.Phase.VICTORY: return "VICTORY"
		Game.Phase.FAIL: return "FAIL"
		_: return "?"
