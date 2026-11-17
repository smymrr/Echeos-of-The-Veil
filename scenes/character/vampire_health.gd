class_name VampireHealth
extends Node

func take_damage(amount: int) -> void:
	get_tree().call_group("ui_boss", "take_damage", amount)


@export var max_health: int = 100
var current_health: int

func _ready() -> void:
	current_health = max_health

func take_damage(amount: int) -> void:
	if current_health <= 0:
		return
		
	current_health = max(0, current_health - amount)
	
	if current_health == 0:
		died.emit()
