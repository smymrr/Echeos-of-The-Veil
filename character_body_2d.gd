extends CharacterBody2D

@onready var movement_component: MovementComponent = $MovementComponent

var last_facing_direction: Vector2 = Vector2.RIGHT

func _physics_process(_delta: float) -> void:
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# 1. Update arah karakter
	if input_direction != Vector2.ZERO:
		last_facing_direction = input_direction.normalized()

	# 2. Dash
	if Input.is_action_just_pressed("dash") and movement_component.can_dash:
		var target_dir = input_direction if input_direction != Vector2.ZERO else last_facing_direction
		var dash_velocity = movement_component.start_dash(target_dir)
		
		if dash_velocity != Vector2.ZERO:
			velocity = dash_velocity
			rotation_degrees = movement_component.get_rotation_degrees(target_dir)

	# Pergerakan biasa
	if not movement_component.is_dashing:
		velocity = movement_component.get_velocity(input_direction)
		if input_direction != Vector2.ZERO:
			rotation_degrees = movement_component.get_rotation_degrees(input_direction)


	move_and_slide()
