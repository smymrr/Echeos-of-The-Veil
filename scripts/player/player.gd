extends CharacterBody2D

@export var movement_component: MovementComponent
@export var attack_component: AttackComponent
@export var animation_component: AnimationComponent
@export var death_screen: PackedScene

@export var sprite: AnimatedSprite2D
@export var camera: Camera2D

var _default_camera_zoom: Vector2 = Vector2.ONE
var last_facing_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	CheckpointManager.apply_respawn(self)

	PlayerData.player = self
	if camera:
		_default_camera_zoom = camera.zoom
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
	
	if input_direction != Vector2.ZERO and not movement_component.is_dashing:
		last_facing_direction = input_direction.normalized()
	
	movement_component.process_dash(last_facing_direction)
	
	velocity = movement_component.get_velocity(input_direction)
	
	if not attack_component.is_attacking:
		movement_component.process_animation(last_facing_direction)

func set_movement_lock(locked: bool, play_idle: bool = false) -> void:
	movement_component.is_dashing = false
	velocity = Vector2.ZERO
	if locked and play_idle:
		movement_component.process_animation(last_facing_direction)
	
	movement_component.is_locked = locked
	print("success", locked)

func set_movement_slowed(slowed: bool) -> void:
	movement_component.is_slowed = slowed

# ================================
# ATTACK
# ================================

func set_attack_enable(enabled: bool) -> void:
	attack_component.can_attack = enabled
	
func attack() -> void:
	var global_mouse_pos = get_global_mouse_position()
	var mouse_angle = global_position.direction_to(global_mouse_pos).angle() # Returns radians between -PI and PI
	var snapped_dir = snapped(mouse_angle, PI/2)
	var dir = Vector2.RIGHT.rotated(snapped_dir)
	
	# Match based on 4 cardinal sectors
	attack_component.try_attack(dir)

func _death(attacker: Node2D) -> void:
	if PlayerData.story_flags.get("boss_scripted_defeat", false):
		_scripted_boss_death()
		return
	var attacker_health_component := attacker.get_node("HealthComponent")
	
	var zoom_tween = create_tween()
	zoom_tween.tween_property(camera, "zoom", Vector2(5, 5), 1.0)
	set_movement_lock(true)
	
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
	await get_tree().create_timer(1).timeout
	
	var death_screen_instance = death_screen.instantiate()
	add_child(death_screen_instance)
	death_screen_instance.show_death(
		attacker.name,
		attacker_health_component.current_health,
		attacker_health_component.max_health
	)

func _scripted_boss_death() -> void:
	var zoom_tween := create_tween()
	zoom_tween.tween_property(camera, "zoom", Vector2(4.0, 4.0), 0.8)
	set_movement_lock(true)

	await get_tree().create_timer(0.4).timeout
	animation_component.play_animation("death", last_facing_direction)
	await get_tree().create_timer(0.9).timeout

	# Capture and shatter the screen from the player's screen position
	var shatter := ScreenShatter.new()
	get_tree().root.add_child(shatter)
	var player_screen_pos := get_global_transform_with_canvas().origin
	await shatter.play(player_screen_pos)

	# Screen is now completely black — reset player state and load the sanctuary
	PlayerData.story_flags["boss_scripted_defeat"] = false
	PlayerData.story_flags["lost_to_prologue_boss"] = true

	PlayerHealth.is_dead = false
	PlayerHealth.heal(PlayerData.get_max_health())
	camera.zoom = _default_camera_zoom
	set_movement_lock(false, true)

	await get_tree().current_scene.change_map("sanctuary", "default")
	shatter.queue_free()
