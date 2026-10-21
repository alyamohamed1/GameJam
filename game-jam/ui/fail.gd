extends CanvasLayer
# FAIL screen. Shown on both peers when phase becomes FAIL. Only the host's
# Restart button is enabled; pressing it RPCs a reload of the house scene
# and resets phase to PRE_USB.

@onready var _button: Button = $Root/VBox/Restart

func _ready() -> void:
	SFX.stop_all()
	var stream: AudioStreamMP3 = load("res://audio/newestalarmsound.mp3")
	if stream:
		stream = stream.duplicate()
		stream.loop = true
		var player := AudioStreamPlayer.new()
		player.name = "AlarmPlayer"
		player.stream = stream
		player.volume_db = 0.0
		player.bus = "Master"
		add_child(player)
		player.play()
	_button.pressed.connect(_on_restart)
	_button.disabled = not multiplayer.is_server()
	if _button.disabled:
		_button.text = "Waiting for host..."

func _on_restart() -> void:
	if not multiplayer.is_server():
		return
	Net.restart.rpc()
