extends CanvasLayer
# P2 home-password modal. Opens on client during BLACKOUT after the
# betrayed-you popup. Shows the P2_HomePassword.png art with a LineEdit
# overlaid on the password field. Correct password = Schopenhaeur2025 →
# `unlocked` emitted; caller restores camera feeds.

signal unlocked

const HOME_PW_TEX := preload("res://art/P2_HomePassword.png")
const CORRECT := "Schopenhaeur2025"
# Image is 2172x724, two states side-by-side at 1086 each.
const REGION_OK := Rect2(0, 0, 1086, 724)
const REGION_WRONG := Rect2(1086, 0, 1086, 724)

@onready var _bg: TextureRect = $Root/Art
@onready var _edit: LineEdit = $Root/Art/Edit
@onready var _unlock: Button = $Root/Art/Unlock

var _showing_wrong: bool = false

func _ready() -> void:
	_set_art(REGION_OK)
	_edit.text_submitted.connect(_on_submit)
	_edit.text_changed.connect(_on_text_changed)
	_unlock.pressed.connect(func() -> void: _on_submit(_edit.text))
	_edit.grab_focus()

func _set_art(region: Rect2) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = HOME_PW_TEX
	atlas.region = region
	_bg.texture = atlas

func _on_text_changed(_t: String) -> void:
	if _showing_wrong:
		_set_art(REGION_OK)
		_showing_wrong = false
	SFX.play_channel("keyboard", "keyboard", -12.0)

func _on_submit(text: String) -> void:
	if text.strip_edges() == CORRECT:
		SFX.play("password_ok")
		unlocked.emit()
		queue_free()
	else:
		SFX.play("password_wrong")
		_set_art(REGION_WRONG)
		_showing_wrong = true

func _unhandled_input(event: InputEvent) -> void:
	# No Esc cancel — modal is required to restore cameras.
	pass
