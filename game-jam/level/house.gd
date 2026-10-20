extends Node2D
# Shared world root. Host sees Camera2D following burglar; client sees
# the Player 2 desk UI with a SubViewport sharing this world_2d.

const DESK_SCENE := preload("res://player2/desk.tscn")

@onready var burglar: Node2D = $Burglar

func _ready() -> void:
	if multiplayer.is_server():
		var cam := Camera2D.new()
		cam.name = "HostCam"
		burglar.add_child(cam)
		cam.make_current()
	else:
		# Client: spawn desk UI as a top-level CanvasLayer-ish Control.
		var desk := DESK_SCENE.instantiate()
		get_tree().root.call_deferred("add_child", desk)
