extends Area2D
## Proyektil: melaju lurus, mengenai player = beri damage lalu hilang.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 320.0
var damage: int = 1
var lifetime: float = 6.0


func _ready() -> void:
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
		PlayerHealth.take_damage(damage, body)
	queue_free()  # kena player ATAU tembok -> hilang


func _draw() -> void:
	draw_circle(Vector2.ZERO, 8.0, Color(1.0, 0.5, 0.1, 0.35))
	draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.8, 0.2))
