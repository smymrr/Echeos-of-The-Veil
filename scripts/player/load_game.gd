extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	var save := PlayerData.load_game()
	PlayerHealth.health_changed.emit()
	if (save == true):
		print("loaded")
	else:
		print("failed to load")
