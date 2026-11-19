extends Area2D
## Peluru player: lurus ke arah mouse. Kena hitbox boss = damage, kena tembok = hilang.

var direction: Vector2 = Vector2.RIGHT
var speed: float = 720.0
var damage: int = 1
var lifetime: float = 1.5


func _ready() -> void:
	body_entered.connect(func(_body: Node) -> void: queue_free())  # tembok
	area_entered.connect(_on_area_entered)                          # hitbox boss


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	var target := area.get_parent()
	if target != null and target.has_method("take_damage"):
		target.take_damage(damage)
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 6.0, Color(0.3, 0.8, 1.0, 0.35))
	draw_circle(Vector2.ZERO, 3.5, Color(0.8, 1.0, 1.0))
