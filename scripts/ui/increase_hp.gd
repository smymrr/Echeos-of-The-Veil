extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	print("Current HP: ", PlayerHealth.current_health)
	print("Healing 5 HP")
	PlayerHealth.heal(5)
	print("Current HP: ", PlayerHealth.current_health)
	print()
