extends TextureRect

# Kecepatan gerak kabut mengalir
@export var fog_speed: Vector2 = Vector2(20, 5)

func _process(delta: float) -> void:
	# Menggeser tekstur di dalam TextureRect tanpa menggeser posisinya di map
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	# Geser offset UV teksturnya
