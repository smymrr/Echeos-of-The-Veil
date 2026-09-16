class_name AnimationComponent
extends Node

@onready var sprite: AnimatedSprite2D = $"../Sprite"

func _ready() -> void:
	sprite.animation_finished.connect(_on_animation_finish)

func _on_animation_finish() -> void:
	print('finish anim: ' + sprite.animation)
	if "attack" in sprite.animation:
		sprite.flip_h = false
		print("finish attack")

func play_animation(prefix: String, direction: Vector2) -> void:
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
				target_anim = prefix + "_right"
				sprite.flip_h = direction.x < 0
	else:
		if direction.y > 0: # Bawah
			target_anim = prefix + "_down"
		else: # Atas
			target_anim = prefix + "_up"
	
	if sprite.animation != target_anim or not sprite.is_playing():
		sprite.play(target_anim)
