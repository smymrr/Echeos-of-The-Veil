class_name MovementComponent
extends Node

# Movement Variables
@export var speed: float = 300.0

@export var dash_speed: float = 1000.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 1.0

# States
var is_dashing: bool = false
var can_dash: bool = true

signal dash_started
signal dash_finished

# Perhitungan velocity pergerakan normal
func get_velocity(input_direction: Vector2) -> Vector2:
	return input_direction * speed

# Perhitungan rotasi berdasarkan vector arah player
func get_rotation_degrees(direction: Vector2) -> float:
	# Jika player menahan tombol A/D maka kunci arah karakter ke kanan/kiri
	if abs(direction.x) >= abs(direction.y):
		if direction.x > 0:
			return 90.0   # Right
		else:
			return 270.0  # Left
	else:
		if direction.y > 0:
			return 180.0  # Down
		else:
			return 0.0    # Up

# Dash Mechanism
func start_dash(direction: Vector2) -> Vector2:
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

func _on_dash_duration_timeout() -> void:
	is_dashing = false
	dash_finished.emit()

func _on_cooldown_timeout() -> void:
	can_dash = true
