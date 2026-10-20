extends CanvasLayer
# Victory screen. Shown on both peers when phase becomes VICTORY. Only
# host's Restart button is enabled; pressing it RPCs a reload.

@onready var _time_label: Label = $Root/Panel/VBox/Time
@onready var _button: Button = $Root/Panel/VBox/Restart

func _ready() -> void:
	SFX.play("victory")
	var t: int = int(Game.run_time)
	_time_label.text = "Run time: %02d:%02d" % [t / 60, t % 60]
	_button.pressed.connect(_on_restart)
	_button.disabled = not multiplayer.is_server()
	if _button.disabled:
		_button.text = "Waiting for host..."

func _on_restart() -> void:
	if not multiplayer.is_server():
		return
	Net.restart.rpc()
