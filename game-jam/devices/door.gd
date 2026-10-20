extends Node2D
# Lockable door. Combines a StaticBody2D collider (blocks the wall opening
# while locked) with an Area2D trigger that gives the burglar an interact
# prompt. house.gd handles the key check; on unlock the collider is
# disabled permanently and the visual swaps to look open.

signal interacted(user: Node)

@export var label: String = "Door"

@onready var _collider_shape: CollisionShape2D = $Collider/Shape
@onready var _visual: ColorRect = $Visual
@onready var _trigger: Area2D = $Trigger
@onready var _label_node: Label = $Label

func _ready() -> void:
	_label_node.text = "[E] %s" % label
	_label_node.hide()
	_trigger.body_entered.connect(_on_entered)
	_trigger.body_exited.connect(_on_exited)

func _on_entered(body: Node) -> void:
	if not body.is_in_group("burglar"):
		return
	_label_node.show()
	body.set_current_zone(self)

func _on_exited(body: Node) -> void:
	if not body.is_in_group("burglar"):
		return
	_label_node.hide()
	body.clear_current_zone(self)

func trigger(user: Node) -> void:
	if not multiplayer.is_server():
		return
	interacted.emit(user)

# Called by house.gd after a successful key check.
func unlock() -> void:
	_collider_shape.set_deferred("disabled", true)
	_visual.color = Color(0.3, 0.2, 0.1, 0.35)
