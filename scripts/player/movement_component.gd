class_name MovementComponent
extends Node

# Movement Variables
@export var speed: float = PlayerData.base_speed

@export var dash_speed: float = 900.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 2.0

@onready var animation_component: AnimationComponent = $"../AnimationComponent"
var body: CharacterBody2D

# States
var is_dashing: bool = false
var can_dash: bool = true

signal dash_started
signal dash_finished

func setup(player_body: CharacterBody2D):
	body = player_body

# Perhitungan velocity pergerakan normal
func get_velocity(input_direction: Vector2) -> Vector2:
	return input_direction * speed

# Dash Mechanism
func process_dash(input_direction: Vector2) -> void:
	if Input.is_action_just_pressed("dash") and can_dash:
		var target_dir = input_direction
		var dash_velocity = _start_dash(target_dir)
		
		if dash_velocity != Vector2.ZERO:
			body.velocity = dash_velocity

func _start_dash(direction: Vector2) -> Vector2:
	if not can_dash or direction == Vector2.ZERO:
		return Vector2.ZERO

	is_dashing = true
	can_dash = false
	dash_started.emit()

	# Timer durasi dash
	get_tree().create_timer(dash_duration).timeout.connect(_on_dash_duration_timeout)
	
	# Timer cooldown dash
	get_tree().create_timer(dash_cooldown).timeout.connect(_on_cooldown_timeout)

	return direction.normalized() * dash_speed


# Animation Process
func process_animation(direction: Vector2) -> void:
	if body.velocity != Vector2.ZERO:
		animation_component.play_animation("walk", direction)
	else:
		animation_component.play_animation("idle",  direction)

# Pergantian states
func _on_dash_duration_timeout() -> void:
	is_dashing = false
	dash_finished.emit()

func _on_cooldown_timeout() -> void:
	can_dash = true
