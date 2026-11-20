class_name HealthComponent
extends Node

signal health_changed(current_health, max_health)
signal died

@export var max_health: int = 100
var current_health: int

func _ready() -> void:
	current_health = max_health

func take_damage(amount: int) -> void:
	if current_health <= 0:
		return
		
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	
	if current_health == 0:
		died.emit()
