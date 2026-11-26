class_name MovementComponent
extends Node

# Movement Variables
@export var speed: float = PlayerData.base_speed

# Dash
@export var dash_distance: float = 100.0   # max distance traveled (pixels)
@export var dash_move_time: float = 0.2    # how long the player actually moves
@export var dash_duration: float = 0.5     # total commit time (match the animation length)
@export var dash_cooldown: float = 2.0     # wait AFTER the dash ends

@export var animation_component: AnimationComponent
@export var attack_component: AttackComponent

const DASH_SFX := preload("res://assets/audio/sfx/player/dash.wav")

var body: CharacterBody2D
var dash_direction: Vector2 = Vector2.ZERO

# States
var is_dashing: bool = false
var is_dash_moving: bool = false   # true only during the movement part of the dash
var is_locked: bool = false
var is_slowed: bool = false
var can_dash: bool = true

signal dash_started
signal dash_finished

func setup(player_body: CharacterBody2D):
	body = player_body

# Perhitungan velocity pergerakan normal
func get_velocity(input_direction: Vector2) -> Vector2:
	if is_locked:
		return Vector2.ZERO
	if is_dashing:
		# Committed: ignore input. Move only during the movement window.
		if is_dash_moving:
			return dash_direction * (dash_distance / dash_move_time)
		return Vector2.ZERO
	if is_slowed:
		return input_direction * speed / 2
	return input_direction * speed

# Dash Mechanism
func process_dash(input_direction: Vector2) -> void:
	if Input.is_action_just_pressed("dash") and can_dash and not is_dashing:
		_start_dash(input_direction)

func _start_dash(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return

	dash_direction = direction.normalized()
	
	AudioManager.play_stream(DASH_SFX)
	
	is_dashing = true
	is_dash_moving = true
	can_dash = false
	
	dash_started.emit()

	# Movement stops early, the animation keeps playing until dash_duration
	get_tree().create_timer(minf(dash_move_time, dash_duration)).timeout.connect(_on_dash_move_timeout)
	get_tree().create_timer(dash_duration).timeout.connect(_on_dash_duration_timeout)

# Animation Process
func process_animation(direction: Vector2) -> void:
	if is_locked:
		return
	
	if is_dashing:
		animation_component.play_animation("dash", dash_direction)
	elif body.velocity != Vector2.ZERO:
		animation_component.play_animation("walk", direction)
	else:
		animation_component.play_animation("idle", direction)

# Pergantian states
func _on_dash_move_timeout() -> void:
	is_dash_moving = false

func _on_dash_duration_timeout() -> void:
	is_dashing = false
	is_dash_moving = false
	dash_finished.emit()
	# Cooldown starts after the dash fully ends
	get_tree().create_timer(dash_cooldown).timeout.connect(_on_cooldown_timeout)

func _on_cooldown_timeout() -> void:
	can_dash = true
