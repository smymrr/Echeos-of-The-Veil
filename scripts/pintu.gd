extends Area2D
## Pintu keluar peta: berpindah scene saat pemain menyentuhnya (tanpa tombol).

## Nama titik masuk di scene tujuan yang dipakai sebagai posisi muncul.
## Disimpan di variabel static agar bertahan setelah scene diganti.
static var spawn_berikut: String = ""

@export_file("*.tscn") var tujuan: String = ""
@export var titik_masuk: String = "Awal"

var _aktif: bool = true


func _ready() -> void:
	collision_layer = 0
	collision_mask = 4
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not _aktif or tujuan == "" or not body.is_in_group("pemain"):
		return
	_aktif = false
	spawn_berikut = titik_masuk
	get_tree().change_scene_to_file.call_deferred(tujuan)
