class_name VampireHealth
extends Node

@export var max_health: int = 500
var current_health: int

func _ready() -> void:
	current_health = max_health
	
	get_tree().call_group("ui_boss", "toggle")
	get_tree().call_group("ui_boss", "set_boss_bar", "Vampire", max_health)

func take_damage(amount: int) -> void:
	if current_health <= 0:
		return
	
	get_tree().call_group("ui_boss", "take_damage", amount)
	current_health = max(0, current_health - amount)
	
	if current_health <= 0:
		max_health = 1000
		var tween = create_tween()
		tween.tween_property(self, "current_health", 1000, 5)
		
		get_tree().call_group("ui_boss", "toggle")
		get_tree().call_group("ui_boss", "set_boss_bar", "Vampire", max_health, "tween")
		await tween.finished
