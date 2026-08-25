extends Node
# DirectionUtils.gd — new file, no scene tree position needed
class_name DirectionUtils

# Perhitungan rotasi berdasarkan vector player
static func snap_to_cardinal(direction: Vector2) -> Vector2:
	# Jika player menahan tombol A/D maka kunci arah karakter ke kanan/kiri
	if abs(direction.x) >= abs(direction.y):
		if direction.x > 0:
			return Vector2.RIGHT  # Right
		else:
			return Vector2.LEFT  # Left
	else:
		if direction.y > 0:
			return Vector2.DOWN  # Down
		else:
			return Vector2.UP    # Up
