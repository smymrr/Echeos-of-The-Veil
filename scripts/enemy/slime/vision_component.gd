class_name VisionComponent
extends Node2D

signal target_spotted(target: Node2D)
signal target_lost

@export var sight_area: Area2D
@export var line_of_sight: RayCast2D

var current_target: Node2D = null

func _ready() -> void:
	line_of_sight.enabled = false
	sight_area.body_entered.connect(_on_body_entered)
	sight_area.body_exited.connect(_on_body_exited)

func _physics_process(_delta: float) -> void:
	if is_instance_valid(current_target):
		line_of_sight.target_position = line_of_sight.to_local(current_target.global_position)
		
		# Check if line of sight is broken
		if line_of_sight.is_colliding():
			var collider = line_of_sight.get_collider()
			if collider != current_target:
				_lose_target()

func has_sight() -> bool:
	if not is_instance_valid(current_target): return false
	if not line_of_sight.is_colliding(): return false
	return line_of_sight.get_collider() == current_target

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		current_target = body
		line_of_sight.enabled = true
		target_spotted.emit(body)

func _on_body_exited(body: Node2D) -> void:
	if body == current_target:
		_lose_target()

func _lose_target() -> void:
	line_of_sight.enabled = false
	current_target = null
	target_lost.emit()
