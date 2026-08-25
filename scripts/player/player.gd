extends CharacterBody2D

@onready var movement_component: MovementComponent = $MovementComponent
@onready var attack_component: AttackComponent = $AttackComponent

var last_facing_direction: Vector2 = Vector2.RIGHT

func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("left_click") and not movement_component.is_dashing:
		attack()

	# 2. Movement
	process_movement()
	move_and_slide()

# ================================
# MOVEMENT
# ================================

func process_movement() -> void:
	var input_direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var has_input: bool = input_direction != Vector2.ZERO
	
	# Update arah terakhir player
	if has_input:
		last_facing_direction = input_direction.normalized()
	
	# Pergerakan biasa
	if not movement_component.is_dashing:
		velocity = movement_component.get_velocity(input_direction)
		if has_input and attack_component.can_attack: 
			rotation_degrees = movement_component.get_rotation_degrees(input_direction)
	
	process_dash(input_direction) # Dash

func process_dash(input_direction: Vector2) -> void:
	if Input.is_action_just_pressed("dash") and movement_component.can_dash:
		var target_dir = input_direction if input_direction != Vector2.ZERO else last_facing_direction
		var dash_velocity = movement_component.start_dash(target_dir)
		
		if dash_velocity != Vector2.ZERO:
			velocity = dash_velocity
			rotation_degrees = movement_component.get_rotation_degrees(target_dir)

# ================================
# ATTACK
# ================================

func attack() -> void:
	var global_mouse_pos = get_global_mouse_position()
	var mouse_angle = global_position.direction_to(global_mouse_pos).angle() # Returns radians between -PI and PI
	var snapped_dir = snapped(mouse_angle, PI/2)
	var dir = Vector2.RIGHT.rotated(snapped_dir)
	
	# Match based on 4 cardinal sectors
	attack_component.try_attack(dir)
