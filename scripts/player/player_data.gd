extends Node

signal stats_changed

var base_max_health: int = 100
var base_attack: int = 10
var base_defense: int = 5
var base_speed: float = 300.0

var attack_modifiers: Dictionary = {}
var defense_modifiers: Dictionary = {}
var speed_modifiers: Dictionary = {}
var max_health_modifiers: Dictionary = {}

func get_max_health() -> int:
	return int(base_max_health * _total_multiplier(max_health_modifiers))

func get_attack() -> int:
	return int(base_attack * _total_multiplier(attack_modifiers))

func get_defense() -> int:
	return int(base_defense * _total_multiplier(defense_modifiers))

func get_speed() -> float:
	return base_speed * _total_multiplier(speed_modifiers)

func _total_multiplier(modifiers: Dictionary) -> float:
	var total := 1.0
	for mod in modifiers.values():
		total *= mod
	return total

# MOdification
func add_modifier(stat_dict: Dictionary, source: String, multiplier: float) -> void:
	stat_dict[source] = multiplier
	stats_changed.emit()

func remove_modifier(stat_dict: Dictionary, source: String) -> void:
	stat_dict.erase(source)
	stats_changed.emit()
