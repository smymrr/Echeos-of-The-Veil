class_name LoadingEffects
extends Node
## Efek visual: background "bernapas", scanline turun, judul berdenyut + berkedip.
## Isi Background / Scanline / Title Labels di inspector. Boleh dikosongkan:
## efek yang tidak punya node akan dilewati.

@export var background: CanvasItem
@export var scanline: CanvasItem
@export var title_labels: Array[NodePath] = []   # path dihitung dari node Effects ini, mis. ../Title

@export_group("Background")
@export var bg_zoom_enabled: bool = true
@export var bg_zoom_amount: float = 1.05
@export var bg_zoom_duration: float = 6.0
@export var bg_pan_amount: float = 60.0
@export var bg_pan_duration: float = 5.0

@export_group("Scanline")
@export var scanline_speed: float = 90.0
@export var scanline_area_height: float = 0.0    # 0 = pakai tinggi viewport
@export var scanline_fade: bool = true
@export var scanline_min_alpha: float = 0.15
@export var scanline_max_alpha: float = 0.6

@export_group("Judul")
@export var pulse_speed: float = 1.5             # durasi tiap setengah siklus (detik): makin besar makin lambat
@export var pulse_min_alpha: float = 0.45        # makin kecil = makin kontras redup-terangnya
@export var pulse_scale_amount: float = 1.03     # sedikit membesar pas paling terang
@export var flicker_chance: float = 0.02         # peluang kedip tiap frame

var _bg_start_pos: Vector2
var _scanline_start_y: float
var _area_height: float
var _labels: Array[Label] = []
var _flickering := false

func _ready() -> void:
	if background:
		_bg_start_pos = background.position
		_start_background_breathing()

	if scanline:
		_scanline_start_y = scanline.position.y
		_area_height = scanline_area_height if scanline_area_height > 0.0 \
				else get_viewport().get_visible_rect().size.y

	for path in title_labels:
		var lbl := get_node_or_null(path) as Label
		if lbl:
			_labels.append(lbl)
		else:
			push_warning("Gagal load label judul di path: %s" % path)

	if _labels.is_empty():
		return

	# Tunggu satu frame supaya ukuran label sudah final, lalu pusatkan pivotnya.
	# Tanpa ini, efek membesar akan bergeser ke kanan-bawah, bukan dari tengah.
	await get_tree().process_frame
	for lbl in _labels:
		_center_pivot(lbl)
		lbl.resized.connect(_center_pivot.bind(lbl))
	_start_title_pulse()


func _process(delta: float) -> void:
	_update_scanline(delta)
	if not _flickering and not _labels.is_empty() and randf() < flicker_chance:
		_flicker()


# ---------------------------------------------------------------
# Judul: berdenyut + berkedip
# ---------------------------------------------------------------

func _center_pivot(lbl: Label) -> void:
	lbl.pivot_offset = lbl.size / 2.0


func _start_title_pulse() -> void:
	while is_inside_tree():
		for lbl in _labels:
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


## Kedip memakai self_modulate, bukan modulate, supaya tidak berebut dengan tween denyut.
func _flicker() -> void:
	_flickering = true
	for lbl in _labels:
		lbl.self_modulate.a = randf_range(0.25, 0.5)
		await get_tree().create_timer(0.05).timeout
		lbl.self_modulate.a = 1.0
	_flickering = false


# ---------------------------------------------------------------
# Scanline & background
# ---------------------------------------------------------------

func _update_scanline(delta: float) -> void:
	if not scanline:
		return
	scanline.position.y += scanline_speed * delta
	if scanline.position.y > _scanline_start_y + _area_height:
		scanline.position.y = _scanline_start_y

	if scanline_fade:
		var progress := fmod(scanline.position.y - _scanline_start_y, _area_height) / _area_height
		scanline.modulate.a = lerp(scanline_min_alpha, scanline_max_alpha, sin(progress * PI))


func _start_background_breathing() -> void:
	if bg_zoom_enabled:
		var zoom_tween := create_tween().set_loops()
		zoom_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		zoom_tween.tween_property(background, "scale", Vector2.ONE * bg_zoom_amount, bg_zoom_duration)
		zoom_tween.tween_property(background, "scale", Vector2.ONE, bg_zoom_duration)

	var pan_tween := create_tween().set_loops()
	pan_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pan_tween.tween_property(background, "position", _bg_start_pos + Vector2(bg_pan_amount, 0), bg_pan_duration)
	pan_tween.tween_property(background, "position", _bg_start_pos - Vector2(bg_pan_amount, 0), bg_pan_duration * 2.0)
	pan_tween.tween_property(background, "position", _bg_start_pos, bg_pan_duration)
