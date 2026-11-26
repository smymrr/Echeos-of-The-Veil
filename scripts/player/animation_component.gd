class_name AnimationComponent
extends Node

@onready var sprite: AnimatedSprite2D = $"../Sprite"

var locked: bool = false

func _ready() -> void:
	sprite.animation_finished.connect(_on_animation_finish)
	sprite.animation_changed.connect(func():
		print("anim -> ", sprite.animation)
		print_stack()
	)

func _on_animation_finish() -> void:
	if "attack" in sprite.animation:
		sprite.flip_h = false

func play_animation(prefix: String, direction: Vector2) -> void:
	if locked:
		return
		
	var target_anim: String
	
	# Prioritaskan pergerakan kiri/kanan
	if abs(direction.x) >= abs(direction.y):
		if direction.x > 0: # Kalau ke kanan
			target_anim = prefix + "_right"
			sprite.flip_h = false
		else: # Kalau ke kiri
			if sprite.sprite_frames.has_animation(prefix + "_left"): # Kalau ada animasi khusus untuk ke kiri
				target_anim = prefix + "_left"
			else:
				target_anim = prefix + "_side"
				sprite.flip_h = direction.x < 0
	else:
		if direction.y > 0: # Bawah
			target_anim = prefix + "_down"
		else: # Atas
			target_anim = prefix + "_up"
	
	if sprite.animation != target_anim or not sprite.is_playing():
		if PlayerHealth.is_dead:
			sprite.play(target_anim)
			locked = true
		else:
			sprite.play(target_anim)
