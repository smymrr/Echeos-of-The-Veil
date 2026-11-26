class_name AttackComponent
extends Node

@export var attack_cooldown: float = 0.5
@export var attack_duration: float = 0.35

@onready var animation_component: AnimationComponent = $"../AnimationComponent"
@onready var movement_component: MovementComponent = $"../MovementComponent"
@onready var hitbox: Area2D = %AttackHitbox
@onready var swing_sword_sfx: AudioStreamPlayer2D = $"../SwingSword"

const SFX = preload("res://assets/audio/sfx/player/sword_attack.wav")

var hitbox_offset: Vector2
var can_attack: bool = true
var is_attacking: bool = false
var _already_hit: Array[Node2D] = []
var player: CharacterBody2D

func _ready() -> void:
	hitbox.monitoring = false
	hitbox_offset = hitbox.position
	player = $".."

func try_attack(input_direction: Vector2) -> bool:
	if not can_attack or input_direction == Vector2.ZERO:
		return false
	_perform_attack(input_direction)
	return true

func _perform_attack(input_direction: Vector2) -> void:
	can_attack = false
	is_attacking = true
	_already_hit.clear()
	
	_process_animation_and_hitbox(input_direction)
	_trigger_attack_sfx()
	get_parent().set_movement_lock(true)
	
	await get_tree().physics_frame

	hitbox.monitoring = true
	
	await get_tree().create_timer(attack_duration).timeout
	
	hitbox.monitoring = false
	get_parent().set_movement_lock(false)
	is_attacking = false

	var remaining := attack_cooldown
	if remaining > 0:
		await get_tree().create_timer(remaining).timeout
	can_attack = true

func _process_animation_and_hitbox(input_direction: Vector2) -> void:
	var cardinal = DirectionUtils.snap_to_cardinal(input_direction)
	hitbox.position = cardinal * hitbox_offset.length()
	
	# Animation
	animation_component.play_animation("attack", cardinal)
	
	# Hitbox orientation
	if cardinal.x != 0:
		hitbox.rotation_degrees = 0
	else:
		hitbox.rotation_degrees = 90.0
		
func _trigger_attack_sfx() -> void:
	AudioManager.play_stream(SFX)

func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body in _already_hit or can_attack:
		return
	
	if body.is_in_group("enemy"):
		_already_hit.append(body)
		var hurt_component = body.find_child("HurtboxComponent")
		if not hurt_component: # If there is no dedicated hurt component
			if body.has_method("take_damage"): # If the take damage function is in the body
				print("damaging boss")
				body.take_damage(PlayerData.get_attack())
			else: # If the take damage function is in the HealthComponentr
				body.get_node("HealthComponent").take_damage(PlayerData.get_attack())
		else:
			hurt_component.damage(PlayerData.get_attack(), player.position)

func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	print("area hit: ", area.name, " | groups: ", area.get_groups())
	var parent := area.get_parent()
	
	if parent.is_in_group("breakable") and parent.has_method("break_object"):
		parent.break_object()
	elif area.is_in_group("projectile"):
		print("is a projectile")
		area.queue_free()
