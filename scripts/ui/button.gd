extends Button

var modif_num = 1

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	print("Kali 2 poin attack")
	PlayerData.add_modifier(PlayerData.attack_modifiers, "multi_modif" + str(modif_num), 2.0)
	modif_num += 1
