extends Node

signal health_changed(current: int, max: int)
signal died

func get_health() -> int:
	return PlayerData.current_health

func take_damage(raw_amount: int) -> void:
	var defense: int = PlayerData.get_defense()
	var final_damage: int = int(max(raw_amount - defense, 0))
	PlayerData.current_health = max(PlayerData.current_health - final_damage, 0)
	health_changed.emit(PlayerData.current_health, PlayerData.get_max_health())
	if PlayerData.current_health <= 0:
		died.emit()
		print("player dead")

func heal(amount: int) -> void:
	PlayerData.current_health = min(PlayerData.current_health + amount, PlayerData.get_max_health())
	health_changed.emit(PlayerData.current_health, PlayerData.get_max_health())
