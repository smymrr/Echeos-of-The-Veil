extends CharacterBody2D

@export var speed: float = 100.0
@export var roam_radius: float = 150.0

enum State { ROAMING, CHASING, RETURNING }
var current_state = State.ROAMING

var player: Node2D = null
var home_position: Vector2
var target_roam_pos: Vector2

# Pastikan nama di scene persis "LineOfSight2D" atau sesuaikan dengan scene Anda
@onready var line_of_sight: RayCast2D = get_node_or_null("LineOfSight2D")

func _ready() -> void:
	home_position = global_position
	target_roam_pos = home_position
	_set_new_roam_target()
	if not line_of_sight:
		print("ERROR: Node LineOfSight2D tidak ditemukan!")

func _physics_process(delta: float) -> void:
	var target_position = Vector2.ZERO
	
	if is_instance_valid(player) and line_of_sight:
		line_of_sight.target_position = line_of_sight.to_local(player.global_position)
	
	match current_state:
		State.ROAMING:
			target_position = target_roam_pos
			if global_position.distance_to(target_roam_pos) < 5.0:
				_set_new_roam_target()
				
			# Jika player masuk area DAN terlihat oleh RayCast, ubah state jadi CHASING
			if is_instance_valid(player) and _is_player_visible():
				current_state = State.CHASING
				print("Musuh mulai MENGEJAR!")
				
		State.CHASING:
			if is_instance_valid(player):
				target_position = player.global_position
				
				# Jika pandangan terhalang tembok / player tidak terlihat lagi
				if not _is_player_visible():
					current_state = State.RETURNING
					print("Player terhalang/hilang, musuh KEMBALI.")
			else:
				player = null
				current_state = State.RETURNING
				
		State.RETURNING:
			target_position = home_position
			if is_instance_valid(player) and _is_player_visible():
				current_state = State.CHASING
			elif global_position.distance_to(home_position) < 5.0:
				global_position = home_position
				current_state = State.ROAMING
				_set_new_roam_target()

	var direction = (target_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

func _set_new_roam_target() -> void:
	var random_x = randf_range(-roam_radius, roam_radius)
	var random_y = randf_range(-roam_radius, roam_radius)
	target_roam_pos = home_position + Vector2(random_x, random_y)

func _is_player_visible() -> bool:
	if not line_of_sight:
		return false
		
	if line_of_sight.is_colliding():
		var collider = line_of_sight.get_collider()
		if collider:
			# Cek objek apa yang ditumbuk raycast
			if collider.is_in_group("player"):
				return true
			else:
				# Jika menumbuk tembok/objek lain, cetak namanya (untuk debugging)
				# print("Raycast menumbuk: ", collider.name)
				pass
	return false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		print("Player terdeteksi masuk area!")

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		current_state = State.RETURNING
		print("Player keluar area!")
