extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	print("Raw damage: 15")
	print("Defense: ", PlayerData.get_defense())
	print("Mitigated dmg: ", (15 - int(PlayerData.get_defense())))
	
	PlayerHealth.take_damage(15)
	print("Player health: ", PlayerHealth.get_health())
	print()
