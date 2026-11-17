extends Node
# DirectionUtils.gd — new file, no scene tree position needed
class_name DirectionUtils

static var current_direction: Vector2

# Perhitungan rotasi berdasarkan vector player
static func snap_to_cardinal(direction: Vector2) -> Vector2:
	# Jika player menahan tombol A/D maka kunci arah karakter ke kanan/kiri
	if abs(direction.x) >= abs(direction.y):
		if direction.x > 0:
			current_direction = Vector2.RIGHT
			return current_direction  # Right
		else:
			current_direction = Vector2.LEFT
			return current_direction  # Left
	else:
		if direction.y > 0:
			current_direction = Vector2.DOWN
			return current_direction  # Down
		else:
			current_direction = Vector2.UP
			return current_direction    # Up

static func get_current_direction() -> Vector2:
	return current_direction
