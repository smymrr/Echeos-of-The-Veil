class_name ConversationManager
extends Node
## Alur percakapan NPC <-> MC. Letakkan satu node di scene dan beri group "ui_dialogue".
## Tampilan dikerjakan TalkBox dan ChoiceBox, script ini hanya mengatur urutan.
##
## Tiap baris menentukan siapa yang bicara: "npc" -> group ui_npc_talk, "mc" -> ui_mc_talk.
## Opsional per baris:
##   "choices": [{"text": "Yes", "goto": 3}, ...]  -> tampilkan pilihan jawaban
##   "end": true                                   -> percakapan selesai di baris ini
##
## Contoh dari NPC / musuh:
##   var cm = get_tree().get_first_node_in_group("ui_dialogue")
##   cm.start([
##       {"who": "npc", "text": "Mau ikut?", "choices": [
##           {"text": "Ya", "goto": 1}, {"text": "Tidak", "goto": 2}]},
##       {"who": "npc", "text": "Bagus!", "end": true},
##       {"who": "npc", "text": "Sayang sekali.", "end": true},
##   ], "MALACHAR", "AELINDRA")
## Lanjut ke baris berikutnya (tombol interaksi milik game): cm.advance()

signal conversation_started
signal conversation_ended
## Dikirim saat pemain memilih jawaban (index mulai dari 0).
signal choice_made(index: int, text: String)

const GROUP := "ui_dialogue"

@export_file("*.tscn") var choice_box_scene := "res://scenes/choice_box.tscn"

var _lines: Array = []
var _page := 0
var _npc: TalkBox
var _mc: TalkBox
var _current: TalkBox
var _choice_box: ChoiceBox
var _pending: Array = []
var _choices_open := false


func _ready() -> void:
	add_to_group(GROUP)


func start(lines: Array, npc_name: String = "MALACHAR", mc_name: String = "AELINDRA") -> void:
	_npc = get_tree().get_first_node_in_group("ui_npc_talk") as TalkBox
	_mc = get_tree().get_first_node_in_group("ui_mc_talk") as TalkBox
	if lines.is_empty() or (_npc == null and _mc == null):
		return
	if _npc:
		_npc.set_speaker(npc_name)
	if _mc:
		_mc.set_speaker(mc_name)
	for box in [_npc, _mc]:
		if box and not box.line_finished.is_connected(_on_line_finished):
			box.line_finished.connect(_on_line_finished)
	_lines = lines
	_page = 0
	_show_page()
	conversation_started.emit()


func is_talking() -> bool:
	return _current != null and _current.visible


## Lewati efek ketik, atau lanjut ke baris berikutnya.
func advance() -> void:
	if not is_talking() or _choices_open:
		return
	if _current.is_typing():
		_current.skip_typing()
		return
	var line: Dictionary = _lines[_page]
	if line.get("end", false):
		end()
		return
	_page += 1
	if _page >= _lines.size():
		end()
	else:
		_show_page()


func end() -> void:
	_close_choices()
	for box in [_npc, _mc]:
		if box:
			box.close()
	var was_talking := _current != null
	_current = null
	if was_talking:
		conversation_ended.emit()


func _show_page() -> void:
	var line: Dictionary = _lines[_page]
	var box := _mc if line.get("who", "npc") == "mc" else _npc
	if box == null:
		end()
		return
	# Hanya satu kotak yang tampil pada satu waktu.
	for b in [_npc, _mc]:
		if b:
			b.visible = (b == box)
	_current = box
	box.show_line(line.get("text", ""), _page, _lines.size())


## Kalau baris ini punya pilihan jawaban, tampilkan setelah teks selesai diketik.
func _on_line_finished() -> void:
	if _current == null or _page >= _lines.size():
		return
	var line: Dictionary = _lines[_page]
	if line.has("choices") and not _choices_open:
		_show_choices(line["choices"])


func _show_choices(choices: Array) -> void:
	_choice_box = _get_choice_box()
	if _choice_box == null:
		push_warning("choice_box tidak ditemukan. Cek path choice_box_scene: " + choice_box_scene)
		return
	_pending = choices
	_choices_open = true
	_choice_box.show_choices(choices)


func _get_choice_box() -> ChoiceBox:
	var box := get_tree().get_first_node_in_group("ui_choice") as ChoiceBox
	if box == null:
		# Belum dipasang di scene? Buat otomatis supaya tetap muncul.
		var scene := load(choice_box_scene) as PackedScene
		if scene:
			box = scene.instantiate() as ChoiceBox
			get_tree().current_scene.add_child(box)
	if box and not box.choice_selected.is_connected(_on_choice_selected):
		box.choice_selected.connect(_on_choice_selected)
	return box


func _close_choices() -> void:
	_choices_open = false
	if _choice_box:
		_choice_box.close()


func _on_choice_selected(index: int) -> void:
	if not _choices_open or index >= _pending.size():
		return
	var choice: Dictionary = _pending[index]
	_close_choices()
	choice_made.emit(index, choice.get("text", ""))
	if choice.has("goto"):
		_page = int(choice["goto"])
	else:
		_page += 1
	if _page >= _lines.size():
		end()
	else:
		_show_page()
