extends Node
## Alur percakapan NPC <-> MC. Letakkan satu node di scene dan beri group "ui_dialogue".
## Tampilan dikerjakan TalkBox dan ChoiceBox, script ini hanya mengatur urutan.
##
## Tiap baris menentukan siapa yang bicara: "npc" -> group ui_npc_talk, "mc" -> ui_mc_talk.
## Opsional per baris:
##   "choices": [{"text": "Yes", "goto": 3}, ...]  -> tampilkan pilihan jawaban
##   "voice": "sfx/voices/malachar_alt"            -> override suara khusus baris ini
##   "end": true                                   -> percakapan selesai di baris ini
##
## Contoh dari NPC / musuh:
##   var cm = get_tree().get_first_node_in_group("ui_dialogue")
##   cm.start([
##       {"who": "npc", "text": "Mau ikut?", "choices": [
##           {"text": "Ya", "goto": 1}, {"text": "Tidak", "goto": 2}]},
##       {"who": "npc", "text": "Bagus!", "end": true},
##       {"who": "npc", "text": "Sayang sekali.", "end": true},
##   ], "sfx/voices/malachar_blip", "MALACHAR", "AELINDRA")
## Lanjut ke baris berikutnya (tombol interaksi milik game): cm.advance()

signal conversation_started
signal conversation_ended()
signal choice_result(result: String)

## Dikirim saat pemain memilih jawaban (index mulai dari 0).
signal choice_made(index: int, text: String)

const GROUP := "ui_dialogue"
const CHOICE_GAP := 8.0
const CHOICE_ROOT := "Root"
const CHOICE_LIST := "Root/Choices"
const TALK_PANEL_PATH := ""

@export_file("*.tscn") var choice_box_scene := "res://scenes/choice_box.tscn"
## Suara blip default untuk MC (relatif terhadap base_audio_dir di AudioManager).
@export var mc_voice_path: String = "res://assets/audio/sfx/player/player_voice.wav"
## Sedikit variasi pitch tiap baris / pengulangan agar tidak terdengar identik.
@export_range(0.0, 0.5, 0.01) var voice_pitch_variance: float = 0.05

var _choice_anchor: Control   # the TalkBox the choices sit above
var _choice_list: Control     # the "Choices" container
var _lines: Array = []
var _page := 0
var _npc: TalkBox
var _mc: TalkBox
var _current: TalkBox
var _choice_box: ChoiceBox
var _pending: Array = []
var _choices_open := false
var _result := ""

var _npc_voice_path := ""
var _active_voice_path := ""
var _voice_player: AudioStreamPlayer


func _ready() -> void:
	add_to_group(GROUP)
	_result = ""


func start(lines: Array, npc_voice_path: String = "", npc_name: String = "MALACHAR", mc_name: String = "AELINDRA") -> void:
	_npc = get_tree().get_first_node_in_group("ui_npc_talk") as TalkBox
	_mc = get_tree().get_first_node_in_group("ui_mc_talk") as TalkBox
	if lines.is_empty() or (_npc == null and _mc == null):
		return

	_npc_voice_path = npc_voice_path

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
		_stop_voice()
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
	_stop_voice()
	_close_choices()
	for box in [_npc, _mc]:
		if box:
			box.close()
	var was_talking := _current != null
	_current = null
	if was_talking:
		conversation_ended.emit()


func _get_talk_panel(box: Node) -> Control:
	if box == null:
		return null
	if TALK_PANEL_PATH != "":
		var path := box.get_node_or_null(TALK_PANEL_PATH) as Control
		if path:
			return path
	if box is Control:
		return box as Control
	return _find_panel(box)


func _find_panel(node: Node) -> Control:
	for child in node.get_children():
		if child is Panel or child is PanelContainer:
			return child as Control
		var found := _find_panel(child)
		if found:
			return found
	return null


func _show_page() -> void:
	var line: Dictionary = _lines[_page]
	var who: String = line.get("who", "npc")
	var box := _mc if who == "mc" else _npc
	if box == null:
		end()
		return

	# Hanya satu kotak yang tampil pada satu waktu.
	for b in [_npc, _mc]:
		if b:
			b.visible = (b == box)
	_current = box

	var text: String = line.get("text", "")
	var default_voice := mc_voice_path if who == "mc" else _npc_voice_path
	var voice_path: String = line.get("voice", default_voice)

	box.show_line(text, _page, _lines.size())

	if text.strip_edges() != "" and voice_path != "":
		_start_voice(voice_path)
	else:
		_stop_voice()


func _start_voice(path: String) -> void:
	_stop_voice()
	_active_voice_path = path
	_spawn_voice_instance()


func _spawn_voice_instance() -> void:
	if _active_voice_path == "":
		return
	_voice_player = AudioManager.play(_active_voice_path, voice_pitch_variance)
	if is_instance_valid(_voice_player) and not _voice_player.finished.is_connected(_on_voice_finished):
		_voice_player.finished.connect(_on_voice_finished)


func _on_voice_finished() -> void:
	# Jika teks masih diketik setelah ~8 detik, ulangi lagi sampai selesai.
	if _active_voice_path == "" or _current == null or not _current.is_typing():
		_stop_voice()
		return
	_spawn_voice_instance()


func _stop_voice() -> void:
	_active_voice_path = ""
	if is_instance_valid(_voice_player):
		if _voice_player.finished.is_connected(_on_voice_finished):
			_voice_player.finished.disconnect(_on_voice_finished)
		_voice_player.stop()
		if not _voice_player.is_queued_for_deletion():
			_voice_player.queue_free()
	_voice_player = null


## Kalau baris ini punya pilihan jawaban, tampilkan setelah teks selesai diketik.
func _on_line_finished() -> void:
	_stop_voice()
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
	_choice_anchor = _get_talk_panel(_current)
	if _choice_anchor == null:
		push_warning("Panel di dalam TalkBox tidak ditemukan. Isi TALK_PANEL_PATH.")

	_choice_list = _choice_box.get_node_or_null(CHOICE_LIST) as Control
	_choice_box.show_choices(choices)
	_place_choice_box()

	# Hidden buttons only collapse the list on the next frame, so place it again
	await get_tree().process_frame
	if not _choices_open:
		return
	_place_choice_box()

	# Follow the talk box and the list if either changes size or position
	for c in [_choice_anchor, _choice_list]:
		if c and not c.item_rect_changed.is_connected(_place_choice_box):
			c.item_rect_changed.connect(_place_choice_box)

	# If the talk box changes size or position while choices are open, follow it
	if _choice_anchor and not _choice_anchor.item_rect_changed.is_connected(_place_choice_box):
		_choice_anchor.item_rect_changed.connect(_place_choice_box)


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
	for c in [_choice_anchor, _choice_list]:
		if c and c.item_rect_changed.is_connected(_place_choice_box):
			c.item_rect_changed.disconnect(_place_choice_box)
	_choice_anchor = null
	_choice_list = null
	if _choice_box:
		_choice_box.close()


## Keeps the choice list just above the talk box, whatever height the text made it.
func _place_choice_box() -> void:
	if not _choices_open or _choice_box == null or _choice_anchor == null or _choice_list == null:
		return
	var root := _choice_box.get_node_or_null(CHOICE_ROOT) as Control
	if root == null:
		return
	var wanted_bottom := _choice_anchor.get_global_rect().position.y - CHOICE_GAP
	var delta := wanted_bottom - _choice_list.get_global_rect().end.y
	if absf(delta) > 0.5:
		root.position.y += delta


func _on_choice_selected(index: int) -> void:
	if not _choices_open or index >= _pending.size():
		return

	var choice: Dictionary = _pending[index]

	if choice.has("result"):
		choice_result.emit(str(choice["result"]))

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
