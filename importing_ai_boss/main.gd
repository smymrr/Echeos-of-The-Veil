extends Node2D
## Main: membangun tembok pembatas arena + ruang boss, dan mengatur UI/game over.

const WALL_COLOR := Color(0.35, 0.37, 0.48)
const T := 20.0                 # tebal tembok
const SCREEN := Vector2(1152, 648)

# Ruang boss: dinding kirinya di x=560 dengan celah pintu di y 274..374
const ROOM_LEFT := 560.0
const GATE_TOP := 274.0
const GATE_BOTTOM := 374.0

@onready var player: CharacterBody2D = $Player
@onready var hp_label: Label = $UI/HPLabel
@onready var message_label: Label = $UI/MessageLabel
@onready var boss: Node2D = $Boss
@onready var walls: Node2D = $Walls

var game_over := false


func _ready() -> void:
	_build_walls()
	player.health_changed.connect(_on_health_changed)
	player.died.connect(_on_player_died)
	boss.died.connect(_on_boss_died)
	message_label.text = "WASD = gerak  |  Klik kiri / Space = tebas pedang ke arah mouse  |  Masuk lewat pintu ke ruang boss"


func _build_walls() -> void:
	# Tembok pinggir layar
	_add_wall(Rect2(0, 0, SCREEN.x, T))                        # atas
	_add_wall(Rect2(0, SCREEN.y - T, SCREEN.x, T))             # bawah
	_add_wall(Rect2(0, 0, T, SCREEN.y))                        # kiri
	_add_wall(Rect2(SCREEN.x - T, 0, T, SCREEN.y))             # kanan
	# Tembok pembatas ruang boss (dua potong, menyisakan pintu di tengah)
	_add_wall(Rect2(ROOM_LEFT, T, T, GATE_TOP - T))                          # atas pintu
	_add_wall(Rect2(ROOM_LEFT, GATE_BOTTOM, T, SCREEN.y - T - GATE_BOTTOM))  # bawah pintu


func _add_wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 2   # layer 2 = tembok
	body.collision_mask = 0
	body.position = rect.position + rect.size / 2.0

	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var col := CollisionShape2D.new()
	col.shape = shape
	body.add_child(col)

	var vis := ColorRect.new()
	vis.color = WALL_COLOR
	vis.size = rect.size
	vis.position = -rect.size / 2.0
	body.add_child(vis)

	walls.add_child(body)


func _on_health_changed(current: int, maximum: int) -> void:
	hp_label.text = "HP: %d / %d" % [current, maximum]


func _on_boss_died() -> void:
	game_over = true
	get_tree().call_group("projectile", "queue_free")  # bersihkan sisa peluru boss
	message_label.text = "MENANG! Boss dikalahkan - tekan R untuk main lagi"


func _on_player_died() -> void:
	if game_over:
		return
	game_over = true
	message_label.text = "GAME OVER - tekan R untuk mengulang"


func _unhandled_input(event: InputEvent) -> void:
	if game_over and event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()
