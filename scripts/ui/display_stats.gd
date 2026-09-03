extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	print("Attack: ", str(PlayerData.get_attack()))
	print("Defense: ", str(PlayerData.get_defense()))
	print("Movement Speed: ", str(PlayerData.get_speed()))
	print("Max HP: ", str(PlayerData.get_max_health()))
	print()
	print("Current HP: ", PlayerHealth.get_health())
	print()
