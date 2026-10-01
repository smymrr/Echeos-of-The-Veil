extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	var save := PlayerData.load_game()
	if (save == true):
		print("loaded")
	else:
		print("failed to load")
