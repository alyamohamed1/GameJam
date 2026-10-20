extends Node
# Autoload "SFX". Centralised sound effects. One-shot sounds get a
# freshly-created AudioStreamPlayer that queue_frees itself. Looped
# sounds are keyed by a string so callers can start/stop by name
# (e.g., "dog_growl", "dog_walk").
#
# All streams are preloaded once in _ready() so there's no file I/O
# during gameplay.

const SFX_PATH := "res://audio/"

const SOUNDS := {
	# Player 1
	"walk1":           "PLAYER 1/WOOD WALKING.mp3",
	"walk2":           "PLAYER 1/WOOD WALKING 2.mp3",
	"walk3":           "PLAYER 1/WOOD WALKING 3.mp3",
	"run":             "PLAYER 1/WOOD RUNNING.mp3",
	"note_pickup":     "PLAYER 1/NOTE PICKING UP.mp3",
	"keyboard":        "PLAYER 1/KEYBOARD TYPING.mp3",
	"password_ok":     "PLAYER 1/PASSWORD ACCEPTED.mp3",
	"password_wrong":  "PLAYER 1/WRONG PASSWORD ERROR.mp3",
	"usb":             "PLAYER 1/USB PLUGGING IN.mp3",
	"door_creak":      "PLAYER 1/DOOR CREEK.mp3",
	"door_open":       "PLAYER 1/DOOR OPENING.mp3",
	"safe_keypad":     "PLAYER 1/SAFE KEYPAY.mp3",
	"safe_open":       "PLAYER 1/SAFE OPENING AND CLOSING.mp3",
	"alarm":           "PLAYER 1/ALARM.mp3",
	# Dog
	"dog_bark":        "DOG/SINGLE DOG BARK.mp3",
	"dog_growl":       "DOG/DOG GROWL.mp3",
	"dog_walk":        "DOG/DOG WALKING.mp3",
	"dog_sniff":       "DOG/DOG SNIFFING.mp3",
	"dog_eat":         "DOG/DOG EATING.mp3",
	"dog_kibble":      "DOG/KIBBLE DOG.mp3",
	# Player 2
	"p2_click":        "PLAYER 2 CONTROL/UI CLICK.mp3",
	"p2_mouse":        "PLAYER 2 CONTROL/PLAYER 2 DESKTOP MOUSE CLICK.mp3",
	"p2_static":       "PLAYER 2 CONTROL/STATIC.mp3",
	"p2_decrypt":      "PLAYER 2 CONTROL/SUCCESS DECRYPT NOISE 1.mp3",
	"power_off":       "PLAYER 2 CONTROL/POWER SHUT OFF FOR LIGHTS 2.mp3",
	"vacuum":          "PLAYER 2 CONTROL/VACUUM.mp3",
	# Shared
	"victory":         "VICTORY PICKED UP ITEM NOISE.mp3",
	"victory_item":    "VICTORY PICKED UP ITEM.mp3",
}

var _streams: Dictionary = {}
var _loops: Dictionary = {}  # key -> AudioStreamPlayer

func _ready() -> void:
	for key in SOUNDS:
		var path: String = SFX_PATH + SOUNDS[key]
		var stream = load(path)
		if stream != null:
			_streams[key] = stream

func play(name: String, volume_db: float = 0.0) -> void:
	if not _streams.has(name):
		return
	var player := AudioStreamPlayer.new()
	player.stream = _streams[name]
	player.volume_db = volume_db
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

func play_random_step() -> void:
	var choices := ["walk1", "walk2", "walk3"]
	play(choices[randi() % choices.size()], -8.0)

func loop(key: String, name: String, volume_db: float = -8.0) -> void:
	if _loops.has(key):
		return
	if not _streams.has(name):
		return
	var stream = _streams[name].duplicate()
	# AudioStreamMP3 / Ogg / Wav all expose `loop` in Godot 4.
	if "loop" in stream:
		stream.loop = true
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	player.play()
	_loops[key] = player

func stop_loop(key: String) -> void:
	if not _loops.has(key):
		return
	_loops[key].queue_free()
	_loops.erase(key)
