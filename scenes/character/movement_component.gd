class_name VampireMovement
extends Node

@onready var sprite: AnimatedSprite2D = $"../Sprite"
@onready var animation_component: VampireAnimation = $"../VampireAnimation"

func _ready() -> void:
	pass

func _physics_process(_delta: float) -> void:
	animation_component.play_animation("movement")
