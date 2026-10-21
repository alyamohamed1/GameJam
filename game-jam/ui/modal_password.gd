extends CanvasLayer
# Password entry popup. Caller connects to `submitted` to validate input;
# if wrong, call set_status() to show a hint. Correct password → caller
# calls close().
# Optional: pass a texture + region via set_image() to show inspect art
# above the password line (e.g., laptop screen state).

signal submitted(text: String)
signal cancelled

@onready var _title: Label = $Root/Panel/Title
@onready var _image: TextureRect = $Root/Panel/Image
@onready var _edit: LineEdit = $Root/Panel/VBox/Edit
@onready var _status: Label = $Root/Panel/VBox/Status

func setup(title_text: String, placeholder: String = "password", secret: bool = true) -> void:
	_title.text = title_text
	_edit.placeholder_text = placeholder
	_edit.secret = secret

func set_image(texture: Texture2D, region: Rect2 = Rect2()) -> void:
	if texture == null:
		_image.visible = false
		return
	if region.size != Vector2.ZERO:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = region
		_image.texture = atlas
	else:
		_image.texture = texture
	_image.visible = true

func set_status(text: String) -> void:
	_status.text = text

func _ready() -> void:
	Game.modal_open = true
	_edit.text_submitted.connect(_on_submit)
	_edit.text_changed.connect(func(_t: String) -> void: SFX.play_channel("keyboard", "keyboard", -12.0))
	_edit.grab_focus()

func _on_submit(text: String) -> void:
	submitted.emit(text)

# Only Esc cancels. Does NOT consume the "interact" (E) action, so typing
# the letter 'e' into the password field does not close the modal.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cancelled.emit()
		close()

func close() -> void:
	Game.modal_open = false
	queue_free()
