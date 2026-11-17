extends CharacterBody2D

@export var movement_component: MovementComponent
@export var attack_component: AttackComponent
@export var animation_component: AnimationComponent

@export var sprite: AnimatedSprite2D
@export var camera: Camera2D

var last_facing_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	PlayerData.player = self
	movement_component.setup(self)
	PlayerHealth.died.connect(_death)

func _physics_process(_delta: float) -> void:
	if PlayerHealth.is_dead:
		return
	
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
	
	if not attack_component.is_attacking:
		movement_component.process_animation(last_facing_direction)
	
	movement_component.process_dash(last_facing_direction) # Dash

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

func _death() -> void:
	var zoom_tween = create_tween()
	zoom_tween.tween_property(camera, "zoom", Vector2(5, 5), 1.0)
	movement_component.set_movement_lock(true)
	
	await get_tree().create_timer(0.5).timeout
	animation_component.play_animation("death", last_facing_direction)
	
	await get_tree().create_timer(2.0).timeout
	
	var drop := sprite.position.y + 20
	var t := create_tween()
	t.tween_property(sprite, "position:y", drop, 0.5) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(sprite, "position:y", drop - 3, 0.1) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(sprite, "position:y", drop, 0.1) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await t.finished
