extends CharacterBody2D

@export var speed: float = 50.0
@export var health: int = 100
@export var roam_radius: float = 150.0 # Jarak maksimal musuh berkeliaran dari posisi asal

@export var attack_damage: int = 10
@export var attack_windup: float = 0.4    # delay before the hit lands
@export var attack_cooldown: float = 1.5

@export var lunge_distance: float = 24.0

@onready var knockback_decay: float = 15.0
@onready var sprite: AnimatedSprite2D = $"Sprite"
@onready var hitbox: Area2D = $"Hitbox"

var attack_tween: Tween

# Status (State) pergerakan musuh
enum State { ROAMING, CHASING, RETURNING, ATTACKING, KNOCKBACK }
var current_state = State.ROAMING

var knockback_velocity = Vector2.ZERO
var player: Node2D = null
var home_position: Vector2
var target_roam_pos: Vector2

var can_attack: bool = true
var attack_cancelled: bool = false

var is_alive: bool = true

func _ready() -> void:
	# Simpan posisi awal musuh saat game pertama kali dijalankan
	home_position = global_position
	target_roam_pos = home_position
	# Langsung mulai roaming begitu game dimuat
	_set_new_roam_target()

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
		
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
				if can_attack and hitbox.overlaps_body(player):
					current_state = State.ATTACKING
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
		State.ATTACKING:
			if can_attack:
				_perform_attack()
			target_position = global_position
		State.KNOCKBACK:
			target_position = global_position
	
	# Melakukan pergerakan menuju target yang aktif
	if not can_attack:
		return
	
	var direction = (target_position - global_position).normalized()
	var normal_velocity = direction * speed
	
	if current_state == State.KNOCKBACK:
		normal_velocity = Vector2.ZERO
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta * 100)
		# Kalau vector knockback sudah habis, lanjutkan roam/mengejar
		if knockback_velocity.length_squared() < 100:
			knockback_velocity = Vector2.ZERO
			current_state = State.CHASING if player else State.ROAMING
	
	velocity = normal_velocity + knockback_velocity
	_process_animation("move")
	
	move_and_slide()

func _perform_attack() -> void:
	can_attack = false
	attack_cancelled = false
	_process_animation("attack")
	
	if not await _wait_or_cancel(attack_windup):
		return
	
	if not is_alive or current_state != State.ATTACKING or player == null:
		can_attack = true
		return
	
	# Lunge toward the player but stop short instead of going into their center
	var start_position = position
	var dir = (player.position - position).normalized()
	var dist = min(lunge_distance, position.distance_to(player.position))
	var lunge_target = position + dir * dist
	
	attack_tween = create_tween()
	attack_tween.tween_property(self, "position", lunge_target, 0.2)\
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		
	attack_tween.tween_callback(_try_hit)  # damage lands at the end of the lunge
	
	attack_tween.tween_property(self, "position", start_position, 0.2)\
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	if not await _wait_or_cancel(attack_cooldown):
		return
	
	can_attack = true
	
	if not is_alive or current_state == State.KNOCKBACK:
		return
	
	if player and hitbox.overlaps_body(player):
		current_state = State.ATTACKING
	elif player:
		current_state = State.CHASING
	else:
		current_state = State.RETURNING

func _try_hit() -> void:
	if is_alive and player and hitbox.overlaps_body(player):
		PlayerHealth.take_damage(attack_damage)

func _cancel_attack_tween() -> void:
	if attack_tween and attack_tween.is_valid():
		attack_tween.kill()
	attack_tween = null

func _wait_or_cancel(duration: float) -> bool:
	var elapsed: float = 0.0
	while elapsed < duration:
		if attack_cancelled:
			can_attack = true
			attack_cancelled = false
			
			return false
		
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	return not attack_cancelled

func _flash_red() -> void:
	var tween = create_tween()
	var damage_color = Color("ff3f2bff")
	modulate = damage_color
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func take_damage(damage: int, attacker_position: Vector2) -> void:
	if not is_alive:
		return
	
	var force: float = 300.0
	
	health = max(0, health - damage)
	_flash_red()
	_cancel_attack_tween()
	
	if health <= 0:
		_death()
		return
	
	attack_cancelled = true
	can_attack = true
	
	var knockback_direction = (position - attacker_position).normalized()
	knockback_velocity = knockback_direction * force
	current_state = State.KNOCKBACK

func _animation_finished() -> void:
	if sprite.animation == "death":
		await get_tree().create_timer(5.0).timeout
		
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color("ffffff00"), 1)
		
		await tween.finished
		
		queue_free()

func _death() -> void:
	_cancel_attack_tween()
	sprite.play("death")
	is_alive = false
	sprite.animation_finished.connect(_animation_finished)

func _set_new_roam_target() -> void:
	# Menentukan titik acak di sekitar home_position berdasarkan roam_radius
	var random_x = randf_range(-roam_radius, roam_radius)
	var random_y = randf_range(-roam_radius, roam_radius)
	target_roam_pos = home_position + Vector2(random_x, random_y)

func _process_animation(prefix: String):
	if prefix == "attack":
		sprite.play(prefix)
	elif prefix == "move":
		sprite.play(prefix)

# --- HUBUNGKAN SINYAL INI DARI NODE Area2D ANDA ---

func _on_sight_body_entered(body: Node2D) -> void:
	# Pastikan objek yang masuk adalah Player (masukkan player ke group "player")
	if body.name == "Player":
		player = body
		current_state = State.CHASING

func _on_sight_body_exited(body: Node2D) -> void:
	if body == player:
		player = null
		# Ketika pemain keluar area deteksi, musuh kembali ke posisi asal dulu sebelum roaming lagi
		current_state = State.RETURNING

func _on_hitbox_body_entered(body: Node2D) -> void:
	if not is_alive or current_state == State.KNOCKBACK:
		return
	
	if body == player:
		current_state = State.ATTACKING
