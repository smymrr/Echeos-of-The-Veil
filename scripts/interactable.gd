extends Area2D
## Area interaksi. Taruh sebagai anak objek apa pun (patung, shrine, portal, dll).
## Pemain menekan E / Enter / Spasi saat berada di dekatnya.

## Dipancarkan saat pemain berinteraksi. Sambungkan dari skrip lain bila perlu.
signal diinteraksi(oleh: Node2D)

@export var judul: String = "Objek"
@export var nama_aksi: String = "Periksa"
## Setiap elemen = satu halaman dialog.
@export var pesan: PackedStringArray = PackedStringArray()
## &"dialog" (biasa), &"portal" (Sanctuary.scene_tujuan), &"pintu" (pakai tujuan), atau &"dungeon" (Overworld.scene_dungeon).
@export var jenis: StringName = &"dialog"
@export var sekali_saja: bool = false
## Dipakai jenis &"pintu": scene tujuan dan nama Marker2D titik masuk di scene itu.
@export_file("*.tscn") var tujuan: String = ""
@export var titik_masuk: String = "Awal"

var _sudah: bool = false


func _ready() -> void:
	add_to_group("interaksi")
	collision_layer = 2
	collision_mask = 0


func interaksi(oleh: Node2D) -> void:
	if sekali_saja and _sudah:
		return
	_sudah = true
	diinteraksi.emit(oleh)
