class_name VampireAttack
extends Node
## Attack logic only: 3 aimed projectiles per shot, and every 4th shot is a circular burst.

@export var projectile_scene: PackedScene
@export var animation_component: VampireAnimation
@export var fire_interval: float = 3.0
@export var projectile_speed: float = 300.0
@export var burst_count: int = 14

@export_group("Ground Attack")
@export var ground_radius: float = 48.0
@export var ground_delay: float = 2.0        # seconds before it bursts
@export var ground_lock_time: float = 1.0
@export var ground_follow_speed: float = 300.0  # px/sec the circle chases the target
@export var ground_damage: int = 25

var is_attacking: bool = false
var target: Node2D = null
var shot_counter: int = 0

@onready var fire_timer: Timer = $FireTimer

func _ready() -> void:
	fire_timer.wait_time = fire_interval
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	print("ready to attack")

func start_attacking(new_target: Node2D) -> void:
	target = new_target
	shot_counter = 0
	fire_timer.start()

func stop_attacking() -> void:
	target = null
	fire_timer.stop()

func _on_fire_timer_timeout() -> void:
	if not is_instance_valid(target):
		return
	
	shot_counter += 1
	is_attacking = true
	if shot_counter % 4 == 0:
		animation_component.play_animation("attack_1")
		await get_tree().create_timer(1).timeout
		_fire_burst()
		print("burst")
	elif shot_counter % 4 == 2:
		animation_component.play_animation("attack_1")
		_ground_attack()
		print("ground attack")
	else:
		animation_component.play_animation("attack_2")
		await get_tree().create_timer(1).timeout
		_fire_aimed()
		print("regular projectile")

func _fire_aimed() -> void:
	var base_angle = (target.global_position - get_parent().global_position).angle()
	for offset in [-0.2, 0.0, 0.2]:
		_spawn_projectile(Vector2.from_angle(base_angle + offset))

func _fire_burst() -> void:
	for i in burst_count:
		_spawn_projectile(Vector2.from_angle(TAU * i / burst_count))

func _spawn_projectile(dir: Vector2) -> void:
	if projectile_scene == null:
		return
	var p := projectile_scene.instantiate()
	p.direction = dir
	p.speed = projectile_speed
	get_tree().current_scene.add_child(p)
	p.global_position = get_parent().global_position
	

func _ground_attack() -> void:
	if not is_instance_valid(target):
		return
	var marker := GroundMarker.new()
	marker.target = target
	marker.radius = ground_radius
	marker.delay = ground_delay
	marker.lock_time = ground_lock_time          # NEW
	marker.follow_speed = ground_follow_speed
	marker.damage = ground_damage
	get_tree().current_scene.add_child(marker)
	marker.global_position = target.global_position

## The circle on the ground: follows the target, fills up, then bursts.
class GroundMarker extends Node2D:
	var target: Node2D
	var radius: float = 48.0
	var delay: float = 1.0
	var lock_time: float = 0.3
	var follow_speed: float = 120.0
	var damage: int = 25

	var elapsed: float = 0.0
	var bursting: bool = false

	func _process(delta: float) -> void:
		if bursting:
			return
		elapsed += delta

		# Phase 1: follow the target while the circle fills up
		if elapsed < delay and is_instance_valid(target):
			global_position = global_position.move_toward(
				target.global_position, follow_speed * delta)

		# Phase 2 (delay <= elapsed < delay + lock_time): frozen in place

		# Phase 3: burst
		if elapsed >= delay + lock_time:
			_burst()

		queue_redraw()

	func _burst() -> void:
		bursting = true
		if is_instance_valid(target) \
				and global_position.distance_to(target.global_position) <= radius \
				and target.is_in_group("player"):
			PlayerHealth.take_damage(damage, target)
		queue_redraw()
		var tw := create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.2)
		tw.tween_callback(queue_free)

	func _draw() -> void:
		if bursting:
			draw_circle(Vector2.ZERO, radius, Color(1, 0.2, 0.2, 0.8))
			return
		var t := clampf(elapsed / delay, 0.0, 1.0)
		var locked := elapsed >= delay
		var fill_alpha := 0.6 if locked else 0.35   # brighter once it locks
		draw_circle(Vector2.ZERO, radius, Color(1, 0.2, 0.2, 0.15))
		draw_circle(Vector2.ZERO, radius * t, Color(1, 0.2, 0.2, fill_alpha))
		draw_arc(Vector2.ZERO, radius, 0, TAU, 48, Color(1, 0.3, 0.3, 0.9), 2.0)
