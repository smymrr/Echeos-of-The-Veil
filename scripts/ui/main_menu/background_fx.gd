extends Control

@onready var background: CanvasItem = $Backround2
@onready var scanline: CanvasItem = $ScanLine

# --- Pengaturan Background ---
@export_group("Background")
@export var bg_zoom_enabled: bool = true        # nyalakan/matikan efek zoom breathing
@export var bg_zoom_amount: float = 1.05        # seberapa besar zoom (1.0 = tidak zoom)
@export var bg_zoom_duration: float = 6.0       # durasi 1x siklus zoom in/out (detik)

@export var bg_pan_amount: float = 60.0         # jarak geser kiri-kanan (px)
@export var bg_pan_duration: float = 5.0        # durasi geser dari titik tengah ke ujung (detik)

# --- Pengaturan Scanline ---
@export_group("Scanline")
@export var scanline_speed: float = 90.0      # px per detik, arah turun
@export var scanline_fade: bool = true        # fade in/out saat bergerak
@export var scanline_min_alpha: float = 0.15
@export var scanline_max_alpha: float = 0.6

# --- Pengaturan Efek Judul ---
@export_group("Judul")
@export var flicker_labels: Array[NodePath] = []
@export var pulse_speed: float = 1.5
@export var pulse_min_alpha: float = 0.45      # makin kecil = makin kontras redup-terangnya
@export var pulse_scale_amount: float = 1.03   # sedikit membesar pas paling terang, biar makin kerasa
@export var flicker_chance: float = 0.02       # peluang kedip tiap frame

var _bg_start_pos: Vector2
var _scanline_start_y: float
var _scanline_area_height: float
var _title_labels: Array[Label] = []


func _ready() -> void:
	if background:
		_bg_start_pos = background.position
		_start_background_breathing()

	if scanline:
		_scanline_start_y = scanline.position.y
		_scanline_area_height = size.y if size.y > 0.0 else 800.0

	for path in flicker_labels:
		var lbl := get_node(path) as Label
		if lbl:
			_title_labels.append(lbl)
		else:
			print("Gagal load label judul di path: ", path)
	_start_title_pulse()


func _start_background_breathing() -> void:
	if bg_zoom_enabled:
		var zoom_tween := create_tween()
		zoom_tween.set_loops()
		zoom_tween.set_trans(Tween.TRANS_SINE)
		zoom_tween.set_ease(Tween.EASE_IN_OUT)
		zoom_tween.tween_property(background, "scale", Vector2.ONE * bg_zoom_amount, bg_zoom_duration)
		zoom_tween.tween_property(background, "scale", Vector2.ONE, bg_zoom_duration)

	var pan_tween := create_tween()
	pan_tween.set_loops()
	pan_tween.set_trans(Tween.TRANS_SINE)
	pan_tween.set_ease(Tween.EASE_IN_OUT)
	pan_tween.tween_property(
		background, "position",
		_bg_start_pos + Vector2(bg_pan_amount, 0), bg_pan_duration
	)
	pan_tween.tween_property(
		background, "position",
		_bg_start_pos - Vector2(bg_pan_amount, 0), bg_pan_duration * 2.0
	)
	pan_tween.tween_property(
		background, "position",
		_bg_start_pos, bg_pan_duration
	)


func _start_title_pulse() -> void:
	while true:
		for lbl in _title_labels:
			var t := create_tween()
			t.set_parallel(true)
			t.tween_property(lbl, "modulate:a", pulse_min_alpha, pulse_speed).set_trans(Tween.TRANS_SINE)
			t.tween_property(lbl, "scale", Vector2.ONE, pulse_speed).set_trans(Tween.TRANS_SINE)
			await t.finished

			var t2 := create_tween()
			t2.set_parallel(true)
			t2.tween_property(lbl, "modulate:a", 1.0, pulse_speed).set_trans(Tween.TRANS_SINE)
			t2.tween_property(lbl, "scale", Vector2.ONE * pulse_scale_amount, pulse_speed).set_trans(Tween.TRANS_SINE)
			await t2.finished
		await get_tree().create_timer(0.1).timeout


func _process(delta: float) -> void:
	if scanline:
		scanline.position.y += scanline_speed * delta
		if scanline.position.y > _scanline_start_y + _scanline_area_height:
			scanline.position.y = _scanline_start_y

		if scanline_fade:
			var progress: float = fmod(scanline.position.y - _scanline_start_y, _scanline_area_height) / _scanline_area_height
			var wave: float = sin(progress * PI)
			var a: float = lerp(scanline_min_alpha, scanline_max_alpha, wave)
			scanline.modulate.a = a

	if randf() < flicker_chance:
		for lbl in _title_labels:
			lbl.modulate.a = randf_range(0.25, 0.5)
			await get_tree().create_timer(0.05).timeout
			lbl.modulate.a = 1.0
