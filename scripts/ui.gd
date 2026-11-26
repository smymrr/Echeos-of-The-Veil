extends CanvasLayer
## Petunjuk interaksi dan kotak dialog dengan efek mengetik.

signal dialog_dibuka
signal dialog_ditutup

var sedang_dialog: bool = false

var _halaman: PackedStringArray = PackedStringArray()
var _idx: int = 0
var _tween: Tween

@onready var petunjuk: Label = $Petunjuk
@onready var kotak: PanelContainer = $Dialog
@onready var judul: Label = $Dialog/Isi/Judul
@onready var teks: Label = $Dialog/Isi/Teks


func _ready() -> void:
	kotak.visible = false
	petunjuk.visible = false


func tampilkan_petunjuk(t: String) -> void:
	petunjuk.text = t
	petunjuk.visible = not sedang_dialog


func sembunyikan_petunjuk() -> void:
	petunjuk.visible = false


func buka_dialog(j: String, halaman: PackedStringArray) -> void:
	if halaman.is_empty():
		halaman = PackedStringArray(["..."])
	_halaman = halaman
	_idx = 0
	judul.text = j
	sedang_dialog = true
	kotak.visible = true
	petunjuk.visible = false
	_tampil_halaman()
	dialog_dibuka.emit()


## Dipanggil saat pemain menekan tombol interaksi ketika dialog terbuka.
func lanjut() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
		teks.visible_ratio = 1.0
		return
	_idx += 1
	if _idx >= _halaman.size():
		tutup()
	else:
		_tampil_halaman()


func tutup() -> void:
	sedang_dialog = false
	kotak.visible = false
	dialog_ditutup.emit()


func _tampil_halaman() -> void:
	teks.text = _halaman[_idx]
	teks.visible_ratio = 0.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(teks, "visible_ratio", 1.0, maxf(0.2, 0.025 * teks.text.length()))
