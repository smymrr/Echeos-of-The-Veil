class_name HealthComponent
extends Node

signal health_changed(current: int, max: int)
signal died

@onready var stats_components: StatsComponent = get_parent().get_node("StatsComponent")

var current_health: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
