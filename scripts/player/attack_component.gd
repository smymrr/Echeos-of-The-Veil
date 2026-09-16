class_name AttackComponent
extends Node

@export var attack_cooldown: float = 0.1
@export var attack_duration: float = 0.2
@export var damage: int = 10
@export var attack_visual_alpha: float = 0.4

@onready var animation_component: AnimationComponent = $"../AnimationComponent"
@onready var hitbox: Area2D = %AttackHitbox
@onready var hitbox_visual: ColorRect = %AttackHitbox/ColorRect
@onready var swing_sword_sfx: AudioStreamPlayer2D = $"../SwingSword"

var hitbox_offset: Vector2
var can_attack: bool = true
var _already_hit: Array[Node2D] = []
var player: CharacterBody2D

func _ready() -> void:
	hitbox.monitoring = false
	hitbox_visual.modulate.a = 0.0  # invisible at start
	hitbox_offset = hitbox.position
	hitbox.body_entered.connect(_on_attack_hitbox_body_entered)
	player = $".."

func try_attack(input_direction: Vector2) -> bool:
	if not can_attack or input_direction == Vector2.ZERO:
		return false
	_perform_attack(input_direction)
	return true

func _perform_attack(input_direction: Vector2) -> void:
	can_attack = false
	_already_hit.clear()
	
	swing_sword_sfx.play()
	_process_animation_and_hitbox(input_direction)
	_trigger_attack_animation()
	_trigger_attack_sfx()

	hitbox.monitoring = true
	hitbox_visual.modulate.a  = 0.4 # show it
	await get_tree().create_timer(attack_duration).timeout
	hitbox.monitoring = false
	hitbox_visual.modulate.a = 0.0                    # hide it again

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

func _trigger_attack_animation() -> void:
	pass

func _trigger_attack_sfx() -> void:
	pass

func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	if body in _already_hit or can_attack:
		return
	
	_already_hit.append(body)
	body.take_damage(PlayerData.get_attack(), player.position)
	print("Dealt ", PlayerData.get_attack(), " Damage")
