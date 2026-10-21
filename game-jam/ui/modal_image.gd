extends CanvasLayer
# Image-based inspect modal. Host spawns on P1 window to show a close-up
# art of an object (fridge note, laptop screen, bookshelf). Optional title
# label + optional action button for pickups. [E]/[Esc] closes.

signal closed
signal action_pressed

@onready var _bg_dim: ColorRect = $Root/Dim
@onready var _image: TextureRect = $Root/Panel/Image
@onready var _title: Label = $Root/Panel/Title
@onready var _caption: Label = $Root/Panel/Caption
@onready var _action: Button = $Root/Panel/Action
@onready var _hint: Label = $Root/Panel/Hint

func setup(title_text: String, texture: Texture2D, region: Rect2 = Rect2(), caption: String = "", action_text: String = "") -> void:
	_title.text = title_text
	if texture != null:
		if region.size != Vector2.ZERO:
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = region
			_image.texture = atlas
		else:
			_image.texture = texture
	_caption.text = caption
	_caption.visible = caption != ""
	if action_text != "":
		_action.text = action_text
		_action.visible = true
	else:
		_action.visible = false

func _ready() -> void:
	Game.modal_open = true
	_action.pressed.connect(func() -> void:
		action_pressed.emit()
		_close())

func _unhandled_input(event: InputEvent) -> void:
	# Only Esc closes. E must NOT close so action-button modals require an
	# explicit click, and passive modals don't collide with world interact.
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()

func _close() -> void:
	Game.modal_open = false
	closed.emit()
	queue_free()
