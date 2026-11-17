class_name VampireAnimation
extends Node

@onready var sprite: AnimatedSprite2D = $"../Sprite"

func play_animation(animation: String) -> void:
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(animation):
		sprite.play(animation)
