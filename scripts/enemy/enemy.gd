extends CharacterBody2D

@export var speed: float = 100.0
@export var roam_radius: float = 150.0 # Jarak maksimal musuh berkeliaran dari posisi asal

# Status (State) pergerakan musuh
enum State { ROAMING, CHASING, RETURNING }
var current_state = State.ROAMING

var player: Node2D = null
var home_position: Vector2
var target_roam_pos: Vector2

func _ready() -> void:
	# Simpan posisi awal musuh saat game pertama kali dijalankan
	home_position = global_position
	target_roam_pos = home_position
	# Langsung mulai roaming begitu game dimuat
	_set_new_roam_target()

func _physics_process(delta: float) -> void:
	var target_position = Vector2.ZERO
	
	# Menentukan target berdasarkan status saat ini
	match current_state:
		State.ROAMING:
			target_position = target_roam_pos
			# Jika sudah sampai di titik acak, cari titik baru
			if global_position.distance_to(target_roam_pos) < 5.0:
				_set_new_roam_target()
				
		State.CHASING:
			if player:
				target_position = player.global_position
			else:
				# Cadangan jika player hilang
				current_state = State.RETURNING
				
		State.RETURNING:
			target_position = home_position
			# Jika sudah kembali dekat posisi asal, kembali roaming
			if global_position.distance_to(home_position) < 5.0:
				global_position = home_position
				current_state = State.ROAMING
				_set_new_roam_target()

	# Melakukan pergerakan menuju target yang aktif
	var direction = (target_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

func _set_new_roam_target() -> void:
	# Menentukan titik acak di sekitar home_position berdasarkan roam_radius
	var random_x = randf_range(-roam_radius, roam_radius)
	var random_y = randf_range(-roam_radius, roam_radius)
	target_roam_pos = home_position + Vector2(random_x, random_y)

# --- HUBUNGKAN SINYAL INI DARI NODE Area2D ANDA ---

func _on_area_2d_body_entered(body: Node2D) -> void:
	# Pastikan objek yang masuk adalah Player (masukkan player ke group "player")
	if body.is_in_group("player"):
		player = body
		current_state = State.CHASING

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		# Ketika pemain keluar area deteksi, musuh kembali ke posisi asal dulu sebelum roaming lagi
		current_state = State.RETURNING
