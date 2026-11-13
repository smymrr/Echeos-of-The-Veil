extends CharacterBody2D
## Player: gerak WASD, serang dengan PEDANG (klik kiri / Spasi / J) ke arah mouse.
## Pedang mengayun membentuk busur: melukai boss dan menghancurkan proyektil.

signal health_changed(current: int, maximum: int)
signal died

@export var speed: float = 260.0
@export var max_health: int = 5
@export var invincible_duration: float = 0.8

@export_group("Pedang")
@export var sword_damage: int = 1
@export var sword_length: float = 70.0
@export var swing_duration: float = 0.22
@export var swing_cooldown: float = 0.35
@export var swing_arc_deg: float = 140.0

var health: int
var invincible_time: float = 0.0

var swing_time: float = 0.0          # > 0 saat pedang sedang mengayun
var cooldown_time: float = 0.0
var swing_center_angle: float = 0.0  # arah tengah ayunan (ke arah mouse)
var sword_angle: float = 0.0
var swing_hit_boss: bool = false     # 1 ayunan = maksimal 1x kena boss

@onready var sword_area: Area2D = $SwordArea


func _ready() -> void:
	add_to_group("player")
	health = max_health
	health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	# --- Gerak WASD ---
	var dir := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	)
	velocity = dir.normalized() * speed
	move_and_slide()
	var size := get_viewport_rect().size
	position = position.clamp(Vector2(16, 16), size - Vector2(16, 16))

	if invincible_time > 0.0:
		invincible_time -= delta

	# --- Pedang ---
	cooldown_time = max(cooldown_time - delta, 0.0)
	if swing_time > 0.0:
		_update_swing(delta)
	else:
		# saat tidak mengayun, pedang menunjuk ke mouse
		sword_angle = (get_global_mouse_position() - global_position).angle()
		if cooldown_time <= 0.0 and _attack_pressed():
			_start_swing()
	queue_redraw()


func _attack_pressed() -> bool:
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) \
		or Input.is_physical_key_pressed(KEY_SPACE) \
		or Input.is_physical_key_pressed(KEY_J)


func _start_swing() -> void:
	swing_time = swing_duration
	cooldown_time = swing_duration + swing_cooldown
	swing_center_angle = (get_global_mouse_position() - global_position).angle()
	swing_hit_boss = false


func _update_swing(delta: float) -> void:
	swing_time -= delta
	var t := 1.0 - clampf(swing_time / swing_duration, 0.0, 1.0)  # 0 -> 1
	var half := deg_to_rad(swing_arc_deg) / 2.0
	sword_angle = swing_center_angle - half + t * 2.0 * half
	sword_area.rotation = sword_angle

	for a in sword_area.get_overlapping_areas():
		if a.is_in_group("boss_hurtbox") and not swing_hit_boss:
			swing_hit_boss = true
			a.get_parent().take_damage(sword_damage)
		elif a.is_in_group("projectile"):
			a.queue_free()  # tangkis peluru


func take_damage(amount: int) -> void:
	if invincible_time > 0.0 or health <= 0:
		return
	health = max(health - amount, 0)
	invincible_time = invincible_duration
	health_changed.emit(health, max_health)
	if health == 0:
		$CollisionShape2D.set_deferred("disabled", true)
		hide()
		died.emit()


func _draw() -> void:
	# Badan
	var blink := invincible_time > 0.0 and int(invincible_time * 20.0) % 2 == 0
	var color := Color(1, 1, 1, 0.4) if blink else Color(0.3, 0.7, 1.0)
	draw_circle(Vector2.ZERO, 14.0, color)
	draw_arc(Vector2.ZERO, 14.0, 0, TAU, 24, Color.WHITE, 2.0)

	# Pedang
	var d := Vector2.from_angle(sword_angle)
	var swinging := swing_time > 0.0
	if swinging:
		# jejak ayunan
		var half := deg_to_rad(swing_arc_deg) / 2.0
		draw_arc(Vector2.ZERO, sword_length * 0.85, swing_center_angle - half, sword_angle, 20, Color(1, 1, 1, 0.35), 10.0)
	var blade_len := sword_length if swinging else 34.0
	draw_line(d * 14.0, d * blade_len, Color(0.88, 0.93, 1.0), 5.0 if swinging else 3.0)
	var guard := d.orthogonal() * 7.0
	draw_line(d * 16.0 - guard, d * 16.0 + guard, Color(0.9, 0.7, 0.2), 3.0)
