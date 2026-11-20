extends Node2D
## Skrip utama peta Sanctuary.

## Scene tujuan saat pemain memasuki portal (isi lewat Inspector).
@export var scene_tujuan: PackedScene
@export var ukuran_peta: Vector2i = Vector2i(1056, 1280)

var _portal_menunggu: bool = false

@onready var pemain: CharacterBody2D = $Objek/Pemain
@onready var ui = $UI
@onready var titik_muncul: Marker2D = $TitikMuncul
@onready var cahaya_portal: PointLight2D = $Objek/Portal/Cahaya


func _ready() -> void:
	pemain.global_position = titik_muncul.global_position

	var kamera: Camera2D = pemain.get_node("Kamera")
	kamera.limit_left = 0
	kamera.limit_top = 0
	kamera.limit_right = ukuran_peta.x
	kamera.limit_bottom = ukuran_peta.y

	for n in get_tree().get_nodes_in_group("interaksi"):
		n.connect("diinteraksi", _on_diinteraksi.bind(n))
	ui.dialog_ditutup.connect(_on_dialog_ditutup)

	var tw := create_tween().set_loops()
	tw.tween_property(cahaya_portal, "energy", 1.1, 1.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(cahaya_portal, "energy", 0.6, 1.6).set_trans(Tween.TRANS_SINE)


func _on_diinteraksi(_oleh: Node2D, objek) -> void:
	_portal_menunggu = objek.jenis == &"portal"
	ui.buka_dialog(objek.judul, objek.pesan)


func _on_dialog_ditutup() -> void:
	if not _portal_menunggu:
		return
	_portal_menunggu = false
	if scene_tujuan:
		preload("res://scripts/pintu.gd").spawn_berikut = "Dari_Sanctuary"
		get_tree().change_scene_to_packed(scene_tujuan)
	else:
		print("[Sanctuary] Isi 'scene_tujuan' pada node Sanctuary (Inspector) agar portal memindahkan pemain.")
