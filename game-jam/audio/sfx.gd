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

# Optional head-trim per sound: start playback N seconds in to skip
# leading silence baked into the source mp3. Populate per sound as
# needed; absent = play from start.
const HEAD_TRIM := {
	# "walk1": 0.05,
}

# Optional tail-trim per sound: stop N seconds before the natural end
# to cut trailing silence. Needs stream.get_length() to be reliable
# (MP3 usually is).
const TAIL_TRIM := {
	# "walk1": 0.1,
}

var _streams: Dictionary = {}
var _loops: Dictionary = {}      # key -> AudioStreamPlayer (looping)
var _channels: Dictionary = {}   # key -> AudioStreamPlayer (one-shot slot)

func _ready() -> void:
	for key in SOUNDS:
		var path: String = SFX_PATH + SOUNDS[key]
		var stream = load(path)
		if stream != null:
			_streams[key] = stream

func play(name: String, volume_db: float = 0.0) -> void:
	_spawn_one_shot(name, volume_db, null)

func _spawn_one_shot(name: String, volume_db: float, channel: Variant) -> AudioStreamPlayer:
	if not _streams.has(name):
		return null
	var stream = _streams[name]
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	var head: float = HEAD_TRIM.get(name, 0.0)
	var tail: float = TAIL_TRIM.get(name, 0.0)
	player.play(head)
	if tail > 0.0 and stream.get_length() > 0.0:
		var dur: float = max(0.05, stream.get_length() - head - tail)
		get_tree().create_timer(dur).timeout.connect(func() -> void:
			if is_instance_valid(player):
				player.stop()
				player.queue_free())
	else:
		player.finished.connect(player.queue_free)
	if channel != null:
		_channels[channel] = player
	return player

# Play on a named channel: a new call stops the previous sound on the same
# channel. Prevents overlap buildup for footsteps, UI clicks, etc.
func play_channel(channel: String, name: String, volume_db: float = 0.0) -> void:
	if _channels.has(channel) and is_instance_valid(_channels[channel]):
		_channels[channel].stop()
		_channels[channel].queue_free()
	_spawn_one_shot(name, volume_db, channel)

func play_random_step() -> void:
	var choices := ["walk1", "walk2", "walk3"]
	play_channel("step", choices[randi() % choices.size()], -8.0)

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

# Kill every running sound (one-shots, channels, loops). Used by the fail
# and victory screens so the game-over sting plays clean.
func stop_all() -> void:
	for key in _loops.keys():
		if is_instance_valid(_loops[key]):
			_loops[key].queue_free()
	_loops.clear()
	for key in _channels.keys():
		if is_instance_valid(_channels[key]):
			_channels[key].queue_free()
	_channels.clear()
	for child in get_children():
		child.queue_free()
