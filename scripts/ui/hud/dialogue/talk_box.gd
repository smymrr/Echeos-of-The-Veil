class_name TalkBox
extends CanvasLayer
## Kotak bicara dengan efek ketik. Dipakai oleh npc_talk_box DAN mc_talk_box
## (pasang script yang sama di root kedua scene; group diatur di editor:
## "ui_npc_talk" / "ui_mc_talk"). Tidak tahu apa-apa soal alur percakapan.

## Dikirim saat seluruh teks baris selesai diketik (otomatis atau dilewati).
signal line_finished

const BASE := "Root/TalkPanel/Content/"
const DOT_ON := Color(0.48, 0.35, 0.82)
const DOT_OFF := Color(0.25, 0.19, 0.48)

## Detik per karakter untuk efek ketik.
@export var seconds_per_char := 0.03

var _tween: Tween
var _dots: Array = []

@onready var _text := get_node_or_null(BASE + "TextBox/DialogueText") as Label
@onready var _name := get_node_or_null(BASE + "SpeakerBox/SpeakerName") as Label


func _ready() -> void:
	for i in range(1, 5):
		_dots.append(get_node_or_null(BASE + "TextBox/BottomRow/PageDots/Page%d" % i))


func set_speaker(speaker: String) -> void:
	if _name:
		_name.text = speaker


## Tampilkan satu baris dengan efek ketik. page = nomor baris (0), total = jumlah baris.
func show_line(content: String, page: int, total: int) -> void:
	if _text == null:
		return
	_text.text = content
	_text.visible_ratio = 0.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_text, "visible_ratio", 1.0, maxf(0.3, content.length() * seconds_per_char))
	_tween.finished.connect(func(): line_finished.emit())
	for i in _dots.size():
		if _dots[i]:
			_dots[i].visible = i < total
			_dots[i].color = DOT_ON if i == page else DOT_OFF


func is_typing() -> bool:
	return _text != null and _text.visible_ratio < 1.0


## Lewati efek ketik, langsung tampilkan semua teks.
func skip_typing() -> void:
	if _tween:
		_tween.kill()
	if _text:
		_text.visible_ratio = 1.0
	line_finished.emit()


func close() -> void:
	visible = false
