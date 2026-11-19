class_name VampireMovement
extends Node

@onready var parent: CharacterBody2D = get_parent()

@export var speed: float = 80.0
@export var arrive_distance: float = 6.0         # how close counts as "arrived"
@export var min_wait_time: float = 1.0           # pause at each point
@export var max_wait_time: float = 3.0
@export var stuck_timeout: float = 2.5           # repick target if blocked this long

var roaming_enabled: bool = true
var target: Vector2
var waiting: bool = false
var stuck_timer: float = 0.0

func start_wait() -> void:
	waiting = true
	parent.velocity = Vector2.ZERO
	await get_tree().create_timer(randf_range(min_wait_time, max_wait_time)).timeout
	waiting = false
	pick_new_target()

func pick_new_target() -> void:
	stuck_timer = 0.0
	target = random_point_in_shape()

func random_point_in_shape() -> Vector2:
	var shape = parent.shape_node.shape
	var local_point := Vector2.ZERO

	if shape is RectangleShape2D:
		var half: Vector2 = shape.size * 0.5
		local_point = Vector2(
			randf_range(-half.x, half.x),
			randf_range(-half.y, half.y)
		)
	elif shape is CircleShape2D:
		var angle := randf() * TAU
		var dist: float = shape.radius * sqrt(randf())  # sqrt = uniform spread
		local_point = Vector2(cos(angle), sin(angle)) * dist
	elif shape is CapsuleShape2D:
		var half_h: float = shape.height * 0.5
		local_point = Vector2(
			randf_range(-shape.radius, shape.radius),
			randf_range(-half_h, half_h)
		)
	else:
		push_warning("BossRoam: unsupported shape type, staying put.")
		return parent.global_position

	# Convert from the shape's local space to world space
	return parent.shape_node.to_global(local_point)
