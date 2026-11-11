class_name HurtboxComponent
extends Area2D

signal took_hit(damage_amount: int, attacker_position: Vector2)

@export var health_component: HealthComponent
@export var sprite: CanvasItem # For hit flashing

func damage(amount: int, attacker_position: Vector2) -> void:
	print("damaged")
	if health_component:
		health_component.take_damage(amount)
		
	_flash_red()
	took_hit.emit(amount, attacker_position)

func _flash_red() -> void:
	if not sprite: return
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color("ff3f2bff"), 0.0)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
