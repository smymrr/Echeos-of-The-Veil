extends Node2D

@export var player_trigger: Area2D
@export var barrier: StaticBody2D


func _ready() -> void:
	player_trigger.body_entered.connect(_on_boss_trigger)

func _on_boss_trigger(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	barrier.set_collision_layer_value(3, true)
