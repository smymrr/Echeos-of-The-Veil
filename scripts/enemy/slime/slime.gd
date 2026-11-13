extends CharacterBody2D

@export var speed: float = 50.0
@export var roam_radius: float = 150.0

@export var attack_damage: int = 10
@export var attack_windup: float = 0.35
@export var attack_cooldown: float = 1.5
@export var lunge_distance: float = 24.0
@export var knockback_decay: float = 15.0

@export var separation_distance: float = 20.0

@export var enemy_name: String = "Slime"
@export var level: int = 1

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hitbox: Area2D = $Hitbox
@onready var overhead: Node2D = $EnemyOverhead

@onready var health_component: HealthComponent = $HealthComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent as HurtboxComponent
@onready var vision_component: VisionComponent = $VisionComponent

enum State { ROAMING, CHASING, RETURNING, ATTACKING, KNOCKBACK, DEAD }
var current_state = State.ROAMING

var knockback_velocity = Vector2.ZERO
var player_target: Node2D = null
var home_position: Vector2
var target_roam_pos: Vector2

var can_attack: bool = true
var attack_cancelled: bool = false
var attack_tween: Tween

var _excepted_body: PhysicsBody2D = null
var _restore_pending := false

func _ready() -> void:
	home_position = global_position
	_set_new_roam_target()
	
	overhead.set_info(enemy_name, level)
	overhead.set_health(health_component.current_health, health_component.max_health)
	
	# Connect component signals
	health_component.died.connect(_on_death)
	hurtbox_component.took_hit.connect(_on_took_hit)
	vision_component.target_spotted.connect(_on_target_spotted)
	vision_component.target_lost.connect(_on_target_lost)
	hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	_try_finish_restore()   # first line, before the early return
	if current_state == State.DEAD or not can_attack:
		return
	
	if current_state == State.DEAD or not can_attack:
		return
		
	var target_position = global_position
	
	match current_state:
		State.ROAMING:
			target_position = target_roam_pos
			if global_position.distance_to(target_roam_pos) < 5.0:
				_set_new_roam_target()
				
		State.CHASING:
			if is_instance_valid(player_target):
				target_position = player_target.global_position
			else:
				current_state = State.RETURNING
				
		State.RETURNING:
			target_position = home_position
			if global_position.distance_to(home_position) < 5.0:
				current_state = State.ROAMING
				
		State.ATTACKING:
			if can_attack:
				_perform_attack()
			target_position = global_position
			
		State.KNOCKBACK:
			target_position = global_position
	
	if not can_attack:
		return
	
	# Movement application
	var direction = (target_position - global_position).normalized()
	var normal_velocity = direction * speed
	
	if current_state == State.KNOCKBACK:
		normal_velocity = Vector2.ZERO
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta * 100)
		if knockback_velocity.length_squared() < 100:
			knockback_velocity = Vector2.ZERO
			_evaluate_state_after_interruption()

	velocity = normal_velocity + knockback_velocity
	_process_animation("move")
	move_and_slide()


func _ignore_collision_with(body: PhysicsBody2D) -> void:
	_excepted_body = body
	_restore_pending = false
	add_collision_exception_with(body)
	body.add_collision_exception_with(self)

func _restore_collision() -> void:
	_restore_pending = true   # real removal happens once they've separated

func _try_finish_restore() -> void:
	if not _restore_pending:
		return
	if not is_instance_valid(_excepted_body):
		_excepted_body = null
		_restore_pending = false
		return
	if global_position.distance_to(_excepted_body.global_position) > separation_distance:
		remove_collision_exception_with(_excepted_body)
		_excepted_body.remove_collision_exception_with(self)
		_excepted_body = null
		_restore_pending = false

# --- COMPONENT SIGNAL HANDLERS ---

func _on_took_hit(_damage: int, attacker_position: Vector2) -> void:
	if current_state == State.DEAD: return
	
	_cancel_attack_tween()
	attack_cancelled = true
	can_attack = true
	
	var knockback_direction = (global_position - attacker_position).normalized()
	knockback_velocity = knockback_direction * 300.0
	current_state = State.KNOCKBACK
	
	overhead.set_health(health_component.current_health, health_component.max_health)
	overhead.focus()

func _on_death() -> void:
	current_state = State.DEAD
	set_collision_layer_value(2, false)
	_cancel_attack_tween()
	sprite.play("death")
	QuestManager.report("kill", "slime")
	set_collision_layer_value(3, false)
	hitbox.set_deferred("monitoring", false)
	hurtbox_component.set_deferred("monitorable", false)
	
	overhead.on_death()
	
	await sprite.animation_finished
	await get_tree().create_timer(5.0).timeout
	var fade = create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 1.0)
	await fade.finished
	queue_free()

func _on_target_spotted(target: Node2D) -> void:
	player_target = target
	if current_state in [State.ROAMING, State.RETURNING]:
		current_state = State.CHASING

func _on_target_lost() -> void:
	player_target = null
	if current_state == State.CHASING:
		current_state = State.RETURNING

func _on_hitbox_body_entered(body: Node2D) -> void:
	if current_state in [State.DEAD, State.KNOCKBACK]: return
	if body == player_target:
		current_state = State.ATTACKING

# --- ATTACK LOGIC ---

func _perform_attack() -> void:
	can_attack = false
	attack_cancelled = false
	_process_animation("attack")
	
	if not await _wait_or_cancel(attack_windup): return
	if current_state != State.ATTACKING or player_target == null:
		can_attack = true
		return
		
	var start_position = global_position
	var dir = (player_target.global_position - global_position).normalized()
	var dist = min(lunge_distance, global_position.distance_to(player_target.global_position))
	var lunge_target = global_position + dir * dist
	
	attack_tween = create_tween()
	attack_tween.tween_callback(_ignore_collision_with.bind(player_target))
	attack_tween.tween_property(self, "global_position", lunge_target, 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	attack_tween.tween_callback(_try_hit)
	attack_tween.tween_property(self, "global_position", start_position, 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	attack_tween.tween_callback(_restore_collision)
	
	if not await _wait_or_cancel(attack_cooldown): return
	can_attack = true
	_evaluate_state_after_interruption()

func _try_hit() -> void:
	if current_state == State.DEAD: return
	if player_target and hitbox.overlaps_body(player_target):
		# Ideally, check if player has a HurtboxComponent here instead of calling PlayerHealth directly
		PlayerHealth.take_damage(attack_damage, player_target)

func _cancel_attack_tween() -> void:
	if attack_tween and attack_tween.is_valid():
		attack_tween.kill()
	attack_tween = null
	_restore_collision()

# --- UTILITIES ---

func _set_new_roam_target() -> void:
	var random_x = randf_range(-roam_radius, roam_radius)
	var random_y = randf_range(-roam_radius, roam_radius)
	target_roam_pos = home_position + Vector2(random_x, random_y)

func _process_animation(anim_name: String) -> void:
	if sprite.animation != anim_name:
		sprite.play(anim_name)

func _evaluate_state_after_interruption() -> void:
	if current_state == State.DEAD: return
	if player_target and hitbox.overlaps_body(player_target):
		current_state = State.ATTACKING
	elif is_instance_valid(player_target) and vision_component.has_sight():
		current_state = State.CHASING
	else:
		current_state = State.RETURNING

func _wait_or_cancel(duration: float) -> bool:
	var elapsed: float = 0.0
	while elapsed < duration:
		if attack_cancelled:
			can_attack = true
			attack_cancelled = false
			return false
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	return not attack_cancelled
