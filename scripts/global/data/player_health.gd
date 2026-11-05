extends Node

signal health_changed(current: int, max: int)
signal died

func get_health() -> int:
	return PlayerData.current_health

func _flash_red(body: CharacterBody2D) -> void:
	var tween = create_tween()
	var damage_color = Color("ff3f2bff")
	body.modulate = damage_color
	tween.tween_property(body, "modulate", Color.WHITE, 0.2)

func take_damage(raw_amount: int, body: CharacterBody2D) -> void:
	var defense: int = PlayerData.get_defense()
	var final_damage: int = int(max(raw_amount - defense, 0))
	
	_flash_red(body)
	PlayerData.current_health = max(PlayerData.current_health - final_damage, 0)
	health_changed.emit(PlayerData.current_health, PlayerData.get_max_health())
	
	if PlayerData.current_health <= 0:
		died.emit()

func heal(amount: int) -> void:
	PlayerData.current_health = min(PlayerData.current_health + amount, PlayerData.get_max_health())
	health_changed.emit(PlayerData.current_health, PlayerData.get_max_health())
