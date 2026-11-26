extends CharacterBody2D

var target_player: Node2D = null
var is_active: bool = false

var roam_area: Area2D
var shape_node: CollisionShape2D

@export var sprite: AnimatedSprite2D
@export var attack_component: VampireAttack
@export var movement_component: VampireMovement
@export var animation_component: VampireAnimation


# The dungeon scene will call this function
func _ready() -> void:
	if not is_active or roam_area == null:
		push_error("BossRoam: roam_area is not assigned.")
		set_physics_process(false)
		return

	# Find the CollisionShape2D inside the Area2D
	for child in roam_area.get_children():
		if child is CollisionShape2D:
			shape_node = child
			break

	if shape_node == null or shape_node.shape == null:
		push_error("BossRoam: roam_area needs a CollisionShape2D with a shape.")
		set_physics_process(false)
		return

	attack_component.start_attacking(target_player)
	movement_component.pick_new_target()

func _physics_process(delta: float) -> void:
	if PlayerHealth.is_dead:
		return
	
	if not attack_component.is_attacking:
		animation_component.play_animation("movement")
	
	if not movement_component.roaming_enabled or movement_component.waiting:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_target: Vector2 = movement_component.target - global_position

	# Arrived -> wait, then pick a new point
	if to_target.length() <= movement_component.arrive_distance:
		movement_component.start_wait()
		return

	velocity = to_target.normalized() * movement_component.speed
	move_and_slide()

	# Stuck detection (hit a wall/obstacle and barely moving)
	if get_real_velocity().length() < movement_component.speed * 0.1:
		movement_component.stuck_timer += delta
		if movement_component.stuck_timer >= movement_component.stuck_timeout:
			movement_component.pick_new_target()
	else:
		movement_component.stuck_timer = 0.0

func activate(player_instance: CharacterBody2D, area: Area2D) -> void:
	target_player = player_instance
	is_active = true
	
	if area == null:
		push_error("BossRoam: roam_area is not assigned in Stage.")
		return
		
	roam_area = area
	
	# Find the CollisionShape2D inside the Area2D
	for child in roam_area.get_children():
		if child is CollisionShape2D:
			shape_node = child
			break

	if shape_node == null or shape_node.shape == null:
		push_error("BossRoam: roam_area needs a CollisionShape2D with a shape.")
		return
		
	set_physics_process(true) # Enable movement now that setup is complete
