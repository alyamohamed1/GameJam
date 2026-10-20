extends Area2D
# Interactable zone. Drop one anywhere in the house, set @export label.
# When the burglar body enters, a floating label appears above it. The
# burglar tracks the most recently entered zone and calls trigger() on
# interact input. Everything host-authoritative: only the host emits
# interacted; the client never fires logic.

signal interacted(user: Node)

@export var label: String = "Thing"

@onready var _label_node: Label = $Label

func _ready() -> void:
	_label_node.text = "[E] %s" % label
	_label_node.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("burglar"):
		return
	_label_node.show()
	body.set_current_zone(self)

func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("burglar"):
		return
	_label_node.hide()
	body.clear_current_zone(self)

# Called by the burglar on the host when the player presses interact.
func trigger(user: Node) -> void:
	if not multiplayer.is_server():
		return
	interacted.emit(user)
