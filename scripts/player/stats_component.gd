class_name StatsComponent
extends Node

signal stats_changed

@onready var health_component: HealthComponent = get_parent().get_node("HealthComponent")

@export var base_max_health: int = 100
@export var base_atk: int = 15
@export var base_def: float = 10.0
@export var base_speed: float = 300.0

var health_multiplier: Dictionary = {}
var atk_multiplier: Dictionary = {}
var def_multiplier: Dictionary = {}
var speed_multiplier: Dictionary = {}

# Getter
func get_max_health() -> int:
	return int(base_max_health * _total_multiplier(health_multiplier))

func get_attack() -> int:
	return int(base_atk * _total_multiplier(atk_multiplier))

func get_defense() -> float:
	return int(base_def * _total_multiplier(def_multiplier))

func get_speed() -> float:
	return int(base_speed * _total_multiplier(speed_multiplier))

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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
