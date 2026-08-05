extends CanvasLayer

func _ready():
	$Panel/VBoxContainer/HBoxContainer/CloseButton.pressed.connect(_on_close_pressed)

func _on_close_pressed():
	queue_free()
