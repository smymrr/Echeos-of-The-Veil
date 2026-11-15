class_name VampireAttack
extends Node
## Attack logic only: 3 aimed projectiles per shot, and every 4th shot is a circular burst.

@export var projectile_scene: PackedScene
@export var fire_interval: float = 1.0
@export var projectile_speed: float = 300.0
@export var burst_count: int = 14

var target: Node2D = null
var shot_counter: int = 0

@onready var fire_timer: Timer = $FireTimer


func _ready() -> void:
	fire_timer.wait_time = fire_interval
	fire_timer.timeout.connect(_on_fire_timer_timeout)


func start_attacking(new_target: Node2D) -> void:
	target = new_target
	shot_counter = 0
	fire_timer.start()


func stop_attacking() -> void:
	target = null
	fire_timer.stop()


func _on_fire_timer_timeout() -> void:
	if not is_instance_valid(target):
		return
	shot_counter += 1
	if shot_counter % 4 == 0:
		_fire_burst()
	else:
		_fire_aimed()


func _fire_aimed() -> void:
	var base_angle := (target.global_position - global_position).angle()
	for offset in [-0.2, 0.0, 0.2]:
		_spawn_projectile(Vector2.from_angle(base_angle + offset))


func _fire_burst() -> void:
	for i in burst_count:
		_spawn_projectile(Vector2.from_angle(TAU * i / burst_count))


func _spawn_projectile(dir: Vector2) -> void:
	if projectile_scene == null:
		return
	var p := projectile_scene.instantiate()
	p.direction = dir
	p.speed = projectile_speed
	get_tree().current_scene.add_child(p)
	p.global_position = global_position
