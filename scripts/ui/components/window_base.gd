extends Control
class_name WindowBase

@onready var title_label: Label = $BackgroundPanel/VBoxContainer/Header/TitleLabel
@onready var close_button: Button = $BackgroundPanel/VBoxContainer/Header/CloseButton
@onready var body_container: MarginContainer = $BackgroundPanel/VBoxContainer/Body

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	# Prevent click-through to game world from this window's panel
	$BackgroundPanel.mouse_filter = Control.MOUSE_FILTER_STOP

func set_title(title: String) -> void:
	if title_label:
		title_label.text = title

func _on_close_pressed() -> void:
	queue_free()
