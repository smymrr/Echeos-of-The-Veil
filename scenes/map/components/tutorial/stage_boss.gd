extends Node2D

@export var roam_area: Area2D
@export var player_trigger: Area2D
@export var barrier: StaticBody2D
@export var boss: PackedScene

@onready var boss_spawner: Marker2D = $BossSpawner

var activated: bool = false

func _ready() -> void:
	player_trigger.body_entered.connect(_on_boss_trigger)

func _on_boss_trigger(body: Node2D) -> void:
	if not body.is_in_group("player") or activated:
		return
	
	# Set activated immediately so the trigger can't fire twice
	activated = true
	get_tree().call_group("ui_boss", "toggle")
	get_tree().call_group("ui_boss", "set_boss_bar", "Vampire", 1000)
	
	# Use call_deferred when modifying physics/collisions inside a body_entered signal
	barrier.set_collision_layer_value(3, true)
	
	var boss_instance = boss.instantiate()
	boss_instance.activate(body, roam_area)
	add_child(boss_instance)
	boss_instance.global_position = boss_spawner.global_position
