extends Node

signal health_changed(current: int, max: int)
signal died

var current_health: int

func _ready() -> void:
	current_health = PlayerData.get_max_health()

func take_damage(raw_amount: int) -> void:
	var defense: int = PlayerData.get_defense()
	var final_damage: int = int(max(raw_amount - defense, 0))
	current_health = max(current_health - final_damage, 0)
	health_changed.emit(current_health, PlayerData.get_max_health())
	if current_health <= 0:
		died.emit()
		print("player dead")

func heal(amount: int) -> void:
	current_health = min(current_health + amount, PlayerData.get_max_health())
	health_changed.emit(current_health, PlayerData.get_max_health())
