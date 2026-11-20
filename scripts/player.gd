extends CharacterBody2D
## Pemain top-down 8 arah.
## Gerak: panah atau WASD. Lari: Shift. Interaksi: E / Enter / Spasi.

@export var kecepatan: float = 100.0
@export var kecepatan_lari: float = 160.0

# Urutan frame di player.png: 0 = bawah, 1 = atas, 2 = kiri, 3 = kanan
const FRAME_BAWAH := 0
const FRAME_ATAS := 1
const FRAME_KIRI := 2
const FRAME_KANAN := 3

var arah_hadap: Vector2 = Vector2.DOWN
var _dekat: Array[Area2D] = []
var _waktu: float = 0.0
var _ui

@onready var sprite: Sprite2D = $Sprite2D
@onready var area_interaksi: Area2D = $Interaksi


func _ready() -> void:
	add_to_group("pemain")
	_ui = get_tree().get_first_node_in_group("ui")
	area_interaksi.area_entered.connect(_on_area_masuk)
	area_interaksi.area_exited.connect(_on_area_keluar)


func _physics_process(delta: float) -> void:
	var dialog_aktif: bool = false
	if _ui != null:
		dialog_aktif = _ui.sedang_dialog
	var input_arah := Vector2.ZERO
	if not dialog_aktif:
		input_arah = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		input_arah += Vector2(
			float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A)),
			float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W)))
		input_arah = input_arah.limit_length(1.0)

	var lari := Input.is_key_pressed(KEY_SHIFT)
	velocity = input_arah * (kecepatan_lari if lari else kecepatan)
	move_and_slide()

	if input_arah != Vector2.ZERO:
		arah_hadap = input_arah
		_waktu += delta * (14.0 if lari else 10.0)
		sprite.position.y = -absf(sin(_waktu)) * 1.5
	else:
		sprite.position.y = 0.0
	_perbarui_frame()


func _process(_delta: float) -> void:
	if _ui == null:
		return
	if _ui.sedang_dialog:
		_ui.sembunyikan_petunjuk()
		return
	var t = _terdekat()
	if t:
		_ui.tampilkan_petunjuk("[E]  %s %s" % [t.nama_aksi, t.judul])
	else:
		_ui.sembunyikan_petunjuk()


func _unhandled_input(event: InputEvent) -> void:
	var tekan: bool = event.is_action_pressed("ui_accept")
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		tekan = true
	if not tekan:
		return
	get_viewport().set_input_as_handled()
	if _ui != null and _ui.sedang_dialog:
		_ui.lanjut()
		return
	var t = _terdekat()
	if t:
		t.interaksi(self)


func _perbarui_frame() -> void:
	if absf(arah_hadap.x) > absf(arah_hadap.y):
		sprite.frame = FRAME_KANAN if arah_hadap.x > 0.0 else FRAME_KIRI
	else:
		sprite.frame = FRAME_BAWAH if arah_hadap.y > 0.0 else FRAME_ATAS


func _terdekat() -> Area2D:
	var terbaik: Area2D = null
	var jarak_min := INF
	for a in _dekat:
		if not is_instance_valid(a):
			continue
		var d := global_position.distance_to(a.global_position)
		if d < jarak_min:
			jarak_min = d
			terbaik = a
	return terbaik


func _on_area_masuk(area: Area2D) -> void:
	if area.has_method("interaksi") and not _dekat.has(area):
		_dekat.append(area)


func _on_area_keluar(area: Area2D) -> void:
	if area.has_method("interaksi"):
		_dekat.erase(area)
