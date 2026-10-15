extends ParallaxBackground

# Kecepatan gerak kabut
@export var fog_speed: Vector2 = Vector2(25, 10)

func _process(delta: float) -> void:
	# Bikin offset ParallaxBackground geser otomatis
	scroll_offset += fog_speed * delta
