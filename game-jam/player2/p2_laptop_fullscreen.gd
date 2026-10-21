extends CanvasLayer
# Player 2 "home laptop" semi-fullscreen. Opened from the desk when
# the hacker clicks the LAPTOP panel after USB plug-in. Shows one of
# three views from P2_Laptop.png and swaps atlas regions on click.
#   DESKTOP -> SECURITY -> PASSWORDS
# X buttons in each window chrome act as BACK (not full-close). On the
# DESKTOP view, X closes the semi-fullscreen entirely.

signal closed

enum View { DESKTOP, SECURITY, PASSWORDS }

const LAPTOP_TEX := preload("res://art/P2_Laptop.png")
const REGION_DESKTOP := Rect2(0, 0, 768, 512)
const REGION_SECURITY := Rect2(768, 0, 768, 512)
const REGION_PASSWORDS := Rect2(768, 512, 768, 512)

@onready var _screen: TextureRect = $Root/Screen
@onready var _dim: ColorRect = $Root/Dim
@onready var _btn_security: Button = $Root/Screen/BtnSecurity
@onready var _btn_passwords: Button = $Root/Screen/BtnPasswords
@onready var _btn_back_sec: Button = $Root/Screen/BtnBackSecurity
@onready var _btn_back_pw: Button = $Root/Screen/BtnBackPasswords
@onready var _close_btn: Button = $Root/CloseBtn

var _view: int = View.DESKTOP

func _ready() -> void:
	_screen.texture = _make_atlas(REGION_DESKTOP)
	_btn_security.pressed.connect(func() -> void: _goto(View.SECURITY))
	_btn_passwords.pressed.connect(func() -> void: _goto(View.PASSWORDS))
	_btn_back_sec.pressed.connect(func() -> void: _goto(View.DESKTOP))
	_btn_back_pw.pressed.connect(func() -> void: _goto(View.SECURITY))
	_close_btn.pressed.connect(_close)
	_dim.gui_input.connect(_on_dim_input)
	_refresh()
	SFX.play("p2_mouse", -8.0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()

func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close()

func _goto(v: int) -> void:
	_view = v
	SFX.play("p2_click")
	_refresh()

func _refresh() -> void:
	match _view:
		View.DESKTOP:
			_screen.texture = _make_atlas(REGION_DESKTOP)
		View.SECURITY:
			_screen.texture = _make_atlas(REGION_SECURITY)
		View.PASSWORDS:
			_screen.texture = _make_atlas(REGION_PASSWORDS)
	_btn_security.visible = _view == View.DESKTOP
	_btn_passwords.visible = _view == View.SECURITY
	_btn_back_sec.visible = _view == View.SECURITY
	_btn_back_pw.visible = _view == View.PASSWORDS

func _make_atlas(region: Rect2) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = LAPTOP_TEX
	a.region = region
	return a

func _close() -> void:
	SFX.play("p2_click")
	closed.emit()
	queue_free()
