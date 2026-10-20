extends ParallaxBackground

# Kecepatan mengalir kabut (X = kanan/kiri, Y = atas/bawah)
@export var fog_speed: Vector2 = Vector2(20, 5)

func _process(delta: float) -> void:
	# Geser offset bawaan ParallaxBackground secara kontinyu
	scroll_offset += fog_speed * delta
