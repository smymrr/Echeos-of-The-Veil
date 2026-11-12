extends TileMapLayer

@export var speed: Vector2 = Vector2(8, 2) # Kecepatan geser asap

func _process(delta):
	position += speed * delta
