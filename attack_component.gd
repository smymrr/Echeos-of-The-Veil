class_name AttackComponent
extends Node

@export var attack_cooldown: float = 0.4
@export var attack_duration: float = 0.2
@export var damage: int = 10
@export var attack_visual_alpha: float = 0.4

@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_visual: ColorRect = $Hitbox/ColorRect

var can_attack: bool = true

func _ready() -> void:
	hitbox.monitoring = false
	hitbox_visual.modulate.a = 0.0  # invisible at start

func try_attack(facing_direction: Vector2) -> bool:
	if not can_attack or facing_direction == Vector2.ZERO:
		return false
	_perform_attack(facing_direction)
	return true

func _perform_attack(facing_direction: Vector2) -> void:
	can_attack = false

	hitbox.global_rotation = facing_direction.angle()
	get_parent().rotation = facing_direction.angle()
	_trigger_attack_animation()
	_trigger_attack_sfx()

	hitbox.monitoring = true
	hitbox_visual.modulate.a  = 0.4 # show it
	await get_tree().create_timer(attack_duration).timeout
	hitbox.monitoring = false
	hitbox_visual.modulate.a = 0.0                    # hide it again

	var remaining := attack_cooldown - attack_duration
	if remaining > 0:
		await get_tree().create_timer(remaining).timeout
	can_attack = true

func _trigger_attack_animation() -> void:
	pass

func _trigger_attack_sfx() -> void:
	pass
