extends CanvasLayer
# Simple read-only popup. Host spawns it on the P1 window to show a note
# (fridge password, "USB plugged in", etc). Press E or Esc to close.

signal closed

@onready var _title: Label = $Root/Panel/VBox/Title
@onready var _body: Label = $Root/Panel/VBox/Body

func setup(title_text: String, body_text: String) -> void:
	_title.text = title_text
	_body.text = body_text

func _ready() -> void:
	Game.modal_open = true

func _unhandled_input(event: InputEvent) -> void:
	# Only Esc closes. E would collide with world interact and spam-reopen.
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()

func _close() -> void:
	Game.modal_open = false
	closed.emit()
	queue_free()
