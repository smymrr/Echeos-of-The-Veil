class_name VampireAnimation
extends Node

@onready var sprite: AnimatedSprite2D = $"../Sprite"

func _ready() -> void:
	print("readt")
	print(sprite.name)

func play_animation(animation: String) -> void:
	sprite.play(animation)
