extends Node2D
## AI Boss TERBANG.
##  IDLE  : diam, menunggu player masuk DetectionArea (= ruang boss)
##  CHASE : player di dalam area -> terbang mengejar (zig-zag) dan menembak
##  DEAD  : HP habis -> jatuh ke tanah lalu menghilang
## Tembakan: 3 peluru terarah; setiap tembakan ke-4 = ledakan melingkar.

signal health_changed(current: int, maximum: int)
signal died

enum State { IDLE, CHASE, DEAD }

@export var projectile_scene: PackedScene
## Area deteksi (= ruang boss). TETAP di posisi awal boss, tidak ikut bergerak.
@export var detection_size: Vector2 = Vector2(552, 608)
@export var max_health: int = 15
@export var move_speed: float = 90.0
@export var keep_distance: float = 100.0
@export var fire_interval: float = 1.0
@export var projectile_speed: float = 300.0
@export var burst_count: int = 14
@export var hover_height: float = 32.0   # tinggi terbang dari bayangan

var health: int
var state: State = State.IDLE
var target: Node2D = null
var shot_counter: int = 0
var area_center: Vector2
var time: float = 0.0
var hit_flash: float = 0.0
var fall: float = 0.0   # 0 = terbang, 1 = sudah jatuh ke tanah (animasi mati)

@onready var detection: Area2D = $DetectionArea
@onready var fire_timer: Timer = $FireTimer
@onready var hurtbox: Area2D = $Hurtbox


func _ready() -> void:
	health = max_health
	health_changed.emit(health, max_health)

	# Area deteksi = persegi ruang boss, dilepas dari boss (top_level)
	area_center = global_position
	detection.top_level = true
	detection.global_position = area_center
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = detection_size
	$DetectionArea/CollisionShape2D.shape = rect_shape

	# Hurtbox (bagian yang bisa ditebas pedang) mengikuti badan yang melayang
	hurtbox.position = Vector2(0, -hover_height)

	detection.body_entered.connect(_on_detection_body_entered)
	detection.body_exited.connect(_on_detection_body_exited)
	fire_timer.wait_time = fire_interval
	fire_timer.timeout.connect(_on_fire_timer_timeout)


func body_position() -> Vector2:
	## Posisi badan boss di udara (dunia)
	return global_position + Vector2(0, -hover_height * (1.0 - fall))


func _process(delta: float) -> void:
	time += delta
	hit_flash = max(hit_flash - delta, 0.0)

	if state == State.CHASE and is_instance_valid(target):
		var to_player := target.global_position - body_position()
		var dist := to_player.length()
		var dir := to_player.normalized()
		var approach := 0.0
		if dist > keep_distance + 30.0:
			approach = move_speed
		elif dist < keep_distance - 30.0:
			approach = -move_speed
		# zig-zag menyamping supaya terasa terbang & sulit ditebak
		var weave := dir.orthogonal() * sin(time * 1.5) * move_speed * 0.7
		global_position += (dir * approach + weave) * delta

		# Tetap di dalam ruang boss
		var limit := Rect2(area_center - detection_size / 2.0, detection_size).grow(-45.0)
		limit.position.y += hover_height
		limit.size.y -= hover_height
		global_position = global_position.clamp(limit.position, limit.end)
	queue_redraw()


# ---------- Deteksi ----------
func _on_detection_body_entered(body: Node2D) -> void:
	if state == State.DEAD:
		return
	if body.is_in_group("player"):
		target = body
		state = State.CHASE
		shot_counter = 0
		fire_timer.start()


func _on_detection_body_exited(body: Node2D) -> void:
	if state == State.DEAD:
		return
	if body == target:
		target = null
		state = State.IDLE
		fire_timer.stop()


# ---------- Menembak ----------
func _on_fire_timer_timeout() -> void:
	if state != State.CHASE or not is_instance_valid(target):
		return
	shot_counter += 1
	if shot_counter % 4 == 0:
		_fire_burst()
	else:
		_fire_aimed()


func _fire_aimed() -> void:
	var base_angle := (target.global_position - body_position()).angle()
	for offset in [-0.2, 0.0, 0.2]:
		_spawn_projectile(Vector2.from_angle(base_angle + offset))


func _fire_burst() -> void:
	for i in burst_count:
		_spawn_projectile(Vector2.from_angle(TAU * i / burst_count))


func _spawn_projectile(dir: Vector2) -> void:
	if projectile_scene == null:
		return
	var p := projectile_scene.instantiate()
	p.direction = dir
	p.speed = projectile_speed
	get_tree().current_scene.add_child(p)
	p.global_position = body_position()


# ---------- Damage & mati ----------
func take_damage(amount: int) -> void:
	if state == State.DEAD:
		return
	health = max(health - amount, 0)
	hit_flash = 0.12
	health_changed.emit(health, max_health)
	if health == 0:
		_die()


func _die() -> void:
	state = State.DEAD
	target = null
	fire_timer.stop()
	hurtbox.set_deferred("monitorable", false)
	detection.set_deferred("monitoring", false)
	died.emit()
	# Animasi: jatuh ke tanah -> memudar -> hilang
	var tw := create_tween()
	tw.tween_property(self, "fall", 1.0, 0.7)
	tw.tween_property(self, "modulate:a", 0.0, 0.9)
	tw.tween_callback(queue_free)


# ---------- Gambar ----------
func _draw() -> void:
	var alert := state == State.CHASE
	var dead := state == State.DEAD

	# Area deteksi (posisi tetap di dunia)
	if not dead:
		var area := Rect2(to_local(area_center) - detection_size / 2.0, detection_size)
		draw_rect(area, Color(1, 0.2, 0.2, 0.10) if alert else Color(1, 1, 1, 0.04))
		draw_rect(area, Color(1, 0.3, 0.3, 0.5) if alert else Color(1, 1, 1, 0.2), false, 2.0)

	# Bayangan di tanah (membuktikan boss sedang terbang)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.35))
	draw_circle(Vector2.ZERO, 36.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Posisi badan (melayang naik-turun)
	var bob := sin(time * 3.0) * 5.0 * (1.0 - fall)
	var c := Vector2(0, -hover_height * (1.0 - fall) + bob)

	# Sayap mengepak
	var flap := sin(time * 14.0) * (1.0 - fall)
	var wing_col := Color(0.55, 0.1, 0.12) if alert else Color(0.3, 0.3, 0.35)
	for side in [-1.0, 1.0]:
		draw_colored_polygon(PackedVector2Array([
			c + Vector2(30.0 * side, -4),
			c + Vector2(85.0 * side, -34 + flap * 24.0),
			c + Vector2(72.0 * side, 8 + flap * 10.0),
			c + Vector2(30.0 * side, 16),
		]), wing_col)

	# Badan
	var body_col := Color(0.8, 0.15, 0.15) if alert else Color(0.4, 0.4, 0.45)
	if dead:
		body_col = Color(0.3, 0.3, 0.32)
	body_col = body_col.lerp(Color.WHITE, clampf(hit_flash / 0.12, 0.0, 1.0))
	draw_circle(c, 40.0, body_col)
	draw_arc(c, 40.0, 0, TAU, 32, Color.WHITE, 3.0)

	# Mata (menghadap player; X saat mati)
	if dead:
		draw_line(c + Vector2(-20, -8), c + Vector2(-8, 4), Color.BLACK, 3.0)
		draw_line(c + Vector2(-20, 4), c + Vector2(-8, -8), Color.BLACK, 3.0)
		draw_line(c + Vector2(8, -8), c + Vector2(20, 4), Color.BLACK, 3.0)
		draw_line(c + Vector2(8, 4), c + Vector2(20, -8), Color.BLACK, 3.0)
	else:
		var look := Vector2.RIGHT
		if is_instance_valid(target):
			look = (target.global_position - body_position()).normalized()
		draw_circle(c + look * 16.0, 10.0, Color.WHITE)
		draw_circle(c + look * 19.0, 5.0, Color.BLACK)

	# Bar HP di atas boss
	if not dead:
		var w := 90.0
		var bar := Rect2(c + Vector2(-w / 2.0, -64), Vector2(w, 8))
		draw_rect(bar, Color(0, 0, 0, 0.6))
		var ratio := float(health) / float(max_health)
		draw_rect(Rect2(bar.position, Vector2(w * ratio, 8)), Color(0.9, 0.2, 0.2))
		draw_rect(bar, Color.WHITE, false, 1.0)
