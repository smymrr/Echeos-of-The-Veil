extends Node2D
## Skrip umum untuk semua scene overworld.
## Node yang dibutuhkan: Objek/Pemain, UI, TitikMasuk (berisi Marker2D).
## Tidak ada collision pada peta; pemain hanya dibatasi tepi peta.

const PintuScript = preload("res://scripts/pintu.gd")

@export var ukuran_peta: Vector2i = Vector2i(1536, 1024)
## Marker yang dipakai bila scene dibuka langsung (tanpa lewat pintu).
@export var titik_awal: String = "Awal"
## Scene dungeon (isi lewat Inspector, dipakai oleh Gerbang Dungeon).
@export_file("*.tscn") var scene_dungeon: String = ""

var _tujuan_menunggu: String = ""
var _titik_menunggu: String = ""

@onready var pemain: CharacterBody2D = $Objek/Pemain
@onready var ui = $UI
@onready var titik_masuk: Node = $TitikMasuk


func _ready() -> void:
	var nama: String = PintuScript.spawn_berikut
	PintuScript.spawn_berikut = ""
	var titik: Node2D = null
	if nama != "":
		titik = titik_masuk.get_node_or_null(nama) as Node2D
	if titik == null:
		titik = titik_masuk.get_node_or_null(titik_awal) as Node2D
	if titik != null:
		pemain.global_position = titik.global_position

	var kamera: Camera2D = pemain.get_node("Kamera")
	kamera.limit_left = 0
	kamera.limit_top = 0
	kamera.limit_right = ukuran_peta.x
	kamera.limit_bottom = ukuran_peta.y

	for n in get_tree().get_nodes_in_group("interaksi"):
		n.connect("diinteraksi", _on_diinteraksi.bind(n))
	ui.dialog_ditutup.connect(_on_dialog_ditutup)


func _physics_process(_delta: float) -> void:
	var batas := Vector2(ukuran_peta)
	pemain.global_position = pemain.global_position.clamp(Vector2(8, 16), batas - Vector2(8, 4))


func _on_diinteraksi(_oleh: Node2D, objek) -> void:
	_tujuan_menunggu = ""
	_titik_menunggu = ""
	if objek.jenis == &"pintu" and objek.tujuan != "":
		_tujuan_menunggu = objek.tujuan
		_titik_menunggu = objek.titik_masuk
	elif objek.jenis == &"dungeon":
		_tujuan_menunggu = scene_dungeon
		_titik_menunggu = "Awal"
		if scene_dungeon == "":
			_tidak_ada_dungeon()
	ui.buka_dialog(objek.judul, objek.pesan)


func _on_dialog_ditutup() -> void:
	if _tujuan_menunggu == "":
		return
	var tujuan := _tujuan_menunggu
	_tujuan_menunggu = ""
	PintuScript.spawn_berikut = _titik_menunggu
	get_tree().change_scene_to_file.call_deferred(tujuan)


func _tidak_ada_dungeon() -> void:
	print("[Overworld] Isi 'scene_dungeon' pada node Overworld (Inspector) agar Gerbang Dungeon berfungsi.")
