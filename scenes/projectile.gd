extends Area2D
## Proyektil: melaju lurus, mengenai player = beri damage lalu hilang.

@export var projectile_owner: CharacterBody2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 320.0
var damage: int = 15
var lifetime: float = 6.0

func _ready() -> void:
	rotation = direction.angle() - deg_to_rad(90)
	add_to_group("projectile")
	add_to_group("enemy_projectile")
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		PlayerHealth.take_damage(damage, body, projectile_owner)
	queue_free()  # kena player ATAU tembok -> hilang
