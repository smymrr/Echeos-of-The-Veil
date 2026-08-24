extends CharacterBody2D

@onready var movement_component: MovementComponent = $MovementComponent
@onready var attack_component: AttackComponent = $AttackComponent

var last_facing_direction: Vector2 = Vector2.RIGHT

func _physics_process(_delta: float) -> void:
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if Input.is_action_just_pressed("left_click") and not movement_component.is_dashing:
		attack()
	
	# 1. Update arah karakter
	if input_direction != Vector2.ZERO:
		last_facing_direction = input_direction.normalized()

	# 2. Dash
	process_movement(input_direction)
	move_and_slide()
	
	
	#if Input.is_action_just_pressed("left_click") and not movement_component.is_dashing:
	#	var mouse_dir := (get_global_mouse_position() - global_position).normalized()
	#	attack_component.try_attack(mouse_dir)
		
	

func get_snapped_angle() -> float:
	var angle_radians = global_position.direction_to(get_global_mouse_position()).angle()
	
	# Convert Godot's radians to degrees (-180 to 180)
	var angle_degrees = rad_to_deg(angle_radians)
	
	# Turn negative degrees into positive 360-degree format
	if angle_degrees < 0:
		angle_degrees += 360.0
		
	# Round to the nearest 90 degrees (0, 90, 180, 270)
	var snapped_angle = round(angle_degrees / 90.0) * 90.0
	
	# Reset 360 back to 0
	if snapped_angle >= 360.0:
		snapped_angle = 0.0
		
	return snapped_angle

# ================================
# MOVEMENT
# ================================

func process_movement(input_direction: Vector2) -> void:
	process_dash(input_direction)
	
	if not movement_component.is_dashing:
		velocity = movement_component.get_velocity(input_direction)
		if input_direction != Vector2.ZERO:
			rotation_degrees = movement_component.get_rotation_degrees(input_direction)

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
	var local_mouse = get_local_mouse_position()
	var angle = local_mouse.angle() # Returns radians between -PI and PI
	print(angle)
	var snapped_dir = snapped(angle, PI/2)
	print(snapped_dir)
	# Match based on 4 cardinal sectors
	if snapped_dir == 0.0:
		print("Attack right")
	elif snapped_dir == PI/2:
		print("Attack down")
	elif snapped_dir == -PI/2:
		print("Attack up")
	else:
		print("Attack left")
	
