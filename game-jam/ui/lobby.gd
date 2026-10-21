extends Control
# Main scene. Pick Host or Join. Net autoload handles the scene swap
# once both peers are connected.

@onready var ip_edit: LineEdit = $Panel/VBox/IPEdit
@onready var status_label: Label = $Panel/VBox/Status
@onready var host_btn: Button = $Panel/VBox/HostBtn
@onready var join_btn: Button = $Panel/VBox/JoinBtn

func _ready() -> void:
	Net.status_changed.connect(_on_status)
	host_btn.pressed.connect(func() -> void: Net.host())
	join_btn.pressed.connect(func() -> void: Net.join(ip_edit.text.strip_edges()))

func _on_status(text: String) -> void:
	status_label.text = text
