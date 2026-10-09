extends Node
## Script demo supaya UI bisa dicoba. Isinya hanya urusan tampil/sembunyi dan efek
## sederhana. Programmer boleh mengganti dengan logika game yang asli.
##
## GameUI hanya berisi: HUD, QuestLog, InventoryPanel, PausePanel.
## Scene lain (boss_bar, wave_label, npc_talk_box, mc_talk_box, choice_box, enemy_overhead)
## berdiri sendiri. Scene itu dicari lewat GROUP, jadi boleh diletakkan di mana saja:
##   boss_bar -> "ui_boss",  wave_label -> "ui_wave",
##   npc_talk_box -> "ui_npc_talk",  mc_talk_box -> "ui_mc_talk",  choice_box -> "ui_choice"
##
## Kontrol:
##   ESC      = tutup Inventory (kalau terbuka), atau buka/tutup Pause
##   J        = buka/tutup Quest
##   I        = buka/tutup Inventory
##   E        = percakapan demo NPC <-> MC (tekan lagi untuk lanjut / lewati ketikan)
##   1 - 4    = pilih jawaban saat pilihan (choice_box) tampil, atau klik dengan mouse
##   1 - 6    = pakai skill (MP berkurang; bos terkena damage kalau tampil)
##   F1       = tampil/sembunyi Boss Bar
##   F2       = tampil/sembunyi teks Wave
##   F3       = minimize / buka semua panel HUD sekaligus (tanpa mouse)
##   F6       = PREVIEW: tampilkan Quest, Boss, Wave, dan Talk NPC sekaligus (tekan lagi = hilang)
##   F7       = tampil/sembunyi seluruh HUD (layar bersih)

const DOT_ON := Color(0.48, 0.35, 0.82)
const DOT_OFF := Color(0.25, 0.19, 0.48)
const SKILL_KEYS := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6]
const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"
const CHOICE_BOX_SCENE := "res://scenes/choice_box.tscn"
const DEMO_CONVERSATION := [
	{"who": "npc", "text": "You dare enter my sanctum, Veilwalker?"},
	{"who": "mc", "text": "I have come for the Veil fragment."},
	{"who": "npc", "text": "Then answer me this: are you ready to pay the price?",
		"choices": [
			{"text": "Yes, I am ready.", "goto": 3},
			{"text": "No, not yet.", "goto": 5},
		]},
	{"who": "npc", "text": "Then take it, and may the Veil forgive you."},
	{"who": "mc", "text": "I will carry it with honor.", "end": true},
	{"who": "npc", "text": "Then leave, and return when you are ready.", "end": true},
]

## Dikirim saat pemain memilih jawaban. Programmer bisa menyambungkannya:
##   ui.choice_made.connect(func(index, text): print(index, text))
signal choice_made(index: int, text: String)

var _quest: CanvasLayer
var _inv: CanvasLayer
var _pause: CanvasLayer

var _frames: Array = []
var _cooldowns: Array = []
var _costs: Array = []
var _sel_style: StyleBox
var _norm_style: StyleBox
var _casting := false

var _mp_bar: ProgressBar
var _mp_value: Label
var _mp := 264.0

var _boss_hp := 2000.0
var _inv_info: Label

var _conversation: Array = []
var _page := 0
var _npc_box: Dictionary = {}
var _mc_box: Dictionary = {}
var _current_box: Dictionary = {}
var _tween: Tween
var _choices_open := false
var _choices_wired := false
var _pending_choices: Array = []
var _confirm: Control
var _pause_menu: Control
var _preview := false


func _ready() -> void:
	# Supaya input tetap diterima saat game di-pause.
	process_mode = Node.PROCESS_MODE_ALWAYS

	_quest = get_node_or_null("QuestLog")
	_inv = get_node_or_null("InventoryPanel")
	_pause = get_node_or_null("PausePanel")
	_confirm = get_node_or_null("PausePanel/Root/ConfirmPanel")
	_pause_menu = get_node_or_null("PausePanel/Root/PausePanel")

	# Hotbar
	for i in range(1, 7):
		var base := "HUD/Root/HotbarPanel/Content/Body/Slots/Skill%d/Frame" % i
		_frames.append(get_node_or_null(base))
		_cooldowns.append(get_node_or_null(base + "/Cooldown"))
		_costs.append(get_node_or_null(base + "/CostLabel"))
	if _frames[0] and _frames[1]:
		_sel_style = _frames[0].get_theme_stylebox("panel")
		_norm_style = _frames[1].get_theme_stylebox("panel")

	# Bar MP
	var mp := "HUD/Root/CharacterPanel/Content/Body/MpRow/"
	_mp_bar = get_node_or_null(mp + "MpBar")
	_mp_value = get_node_or_null(mp + "MpValue")
	if _mp_bar:
		_mp = _mp_bar.value

	# Inventory
	var ib := "InventoryPanel/Root/InvPanel/Content/"
	_inv_info = get_node_or_null(ib + "ItemInfo")
	var close := get_node_or_null(ib + "HeaderRow/CloseButton") as Button
	if close:
		close.pressed.connect(_toggle_inventory)
	for i in range(1, 21):
		var slot := get_node_or_null(ib + "Grid/Slot%d" % i) as Button
		if slot:
			slot.pressed.connect(_on_slot_pressed.bind(i))

	# Tombol Pause
	_connect_button("ResumeButton", toggle_pause)
	_connect_button("SaveButton", func(): print("SAVE: sambungkan ke sistem save"))
	_connect_button("LoadButton", func(): print("LOAD: sambungkan ke sistem load"))
	_connect_button("OptionsButton", func(): print("OPTIONS: tampilkan panel Options"))
	_connect_button("MainMenuButton", _go_main_menu)
	_connect_button("QuitButton", _show_quit_confirm)
	_connect_confirm("YesButton", _go_main_menu)
	_connect_confirm("NoButton", _hide_quit_confirm)


func _connect_button(button_name: String, action: Callable) -> void:
	var path := "PausePanel/Root/PausePanel/Content/ButtonList/" + button_name
	var b := get_node_or_null(path) as Button
	if b:
		b.pressed.connect(action)


func _connect_confirm(button_name: String, action: Callable) -> void:
	var b := get_node_or_null("PausePanel/Root/ConfirmPanel/Content/Buttons/" + button_name) as Button
	if b:
		b.pressed.connect(action)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key: int = event.keycode
	if key == KEY_ESCAPE:
		if _confirm and _confirm.visible:
			_hide_quit_confirm()
		elif _inv and _inv.visible:
			_toggle_inventory()
		else:
			toggle_pause()
		return
	if get_tree().paused:
		return
	if _choices_open:
		var c := [KEY_1, KEY_2, KEY_3, KEY_4].find(key)
		if c != -1 and c < _pending_choices.size():
			_on_choice_pressed(c)
		return
	match key:
		KEY_J:
			_toggle(_quest)
		KEY_I:
			_toggle_inventory()
		KEY_E:
			_on_interact()
		KEY_F1:
			_toggle_boss()
		KEY_F2:
			_toggle(get_tree().get_first_node_in_group("ui_wave"))
		KEY_F3:
			_toggle_all_minimize()
		KEY_F6:
			_toggle_preview()
		KEY_F7:
			_toggle(get_node_or_null("HUD"))
		_:
			var i := SKILL_KEYS.find(key)
			if i != -1:
				_use_skill(i)


func _process(delta: float) -> void:
	# MP pulih pelan-pelan.
	if get_tree().paused or _mp_bar == null:
		return
	_mp = minf(_mp + 5.0 * delta, _mp_bar.max_value)
	_update_mp()


# ---------------------------------------------------------------- Pause
func toggle_pause() -> void:
	var pausing := not get_tree().paused
	get_tree().paused = pausing
	if _pause:
		_pause.visible = pausing
	if not pausing:
		_hide_quit_confirm()
	if pausing:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _show_quit_confirm() -> void:
	if _confirm:
		_confirm.visible = true
	if _pause_menu:
		_pause_menu.visible = false


func _hide_quit_confirm() -> void:
	if _confirm:
		_confirm.visible = false
	if _pause_menu:
		_pause_menu.visible = true


func _go_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


# ------------------------------------------------------------ Tampil/sembunyi
func _toggle(node) -> void:
	if node:
		node.visible = not node.visible


func _toggle_inventory() -> void:
	if _inv == null:
		return
	_inv.visible = not _inv.visible
	if _inv.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _toggle_all_minimize() -> void:
	var buttons: Array = []
	for layer in [get_node_or_null("HUD"), _quest]:
		if layer:
			buttons.append_array(layer.find_children("MinimizeButton", "Button", true, false))
	if buttons.is_empty():
		return
	var minimize: bool = not buttons[0].button_pressed
	for b in buttons:
		b.button_pressed = minimize


func _toggle_preview() -> void:
	_preview = not _preview
	for group in ["ui_boss", "ui_wave", "ui_npc_talk"]:
		var node := get_tree().get_first_node_in_group(group) as CanvasLayer
		if node:
			node.visible = _preview
	if _quest:
		_quest.visible = _preview
	if _preview:
		_update_boss()


func _on_slot_pressed(index: int) -> void:
	if _inv_info:
		_inv_info.text = "Slot %d: (empty)" % index


# ------------------------------------------------------------------- Boss
func _toggle_boss() -> void:
	var layer := get_tree().get_first_node_in_group("ui_boss") as CanvasLayer
	if layer == null:
		return
	layer.visible = not layer.visible
	if layer.visible:
		var bar := layer.get_node_or_null("Root/BossGroup/BossBar") as ProgressBar
		_boss_hp = bar.max_value if bar else 2000.0
		_update_boss()


func _damage_boss(amount: float) -> void:
	var layer := get_tree().get_first_node_in_group("ui_boss") as CanvasLayer
	if layer == null or not layer.visible:
		return
	_boss_hp = maxf(0.0, _boss_hp - amount)
	_update_boss()
	if _boss_hp <= 0.0:
		layer.visible = false


func _update_boss() -> void:
	var layer := get_tree().get_first_node_in_group("ui_boss") as CanvasLayer
	if layer == null:
		return
	var bar := layer.get_node_or_null("Root/BossGroup/BossBar") as ProgressBar
	var value := layer.get_node_or_null("Root/BossGroup/BossHpValue") as Label
	if bar:
		bar.value = _boss_hp
	if value and bar:
		value.text = "%d / %d" % [int(_boss_hp), int(bar.max_value)]


# ---------------------------------------------------------------- Skill
func _use_skill(i: int) -> void:
	if _casting or i >= _frames.size():
		return
	_select_skill(i)
	var cost := 0
	if _costs[i]:
		cost = int(_costs[i].text)
	if _mp < cost:
		return
	_mp -= cost
	_update_mp()
	_casting = true
	if _cooldowns[i]:
		_cooldowns[i].visible = true
	_damage_boss(60.0)
	await get_tree().create_timer(0.6).timeout
	if _cooldowns[i]:
		_cooldowns[i].visible = false
	_casting = false


func _select_skill(index: int) -> void:
	if _sel_style == null or _norm_style == null:
		return
	for k in _frames.size():
		if _frames[k]:
			_frames[k].add_theme_stylebox_override("panel", _sel_style if k == index else _norm_style)


func _update_mp() -> void:
	if _mp_bar:
		_mp_bar.value = _mp
	if _mp_value and _mp_bar:
		_mp_value.text = "%d/%d" % [int(_mp), int(_mp_bar.max_value)]


# ------------------------------------------------------------- Percakapan
## Panggil dari NPC / musuh yang bisa bicara. Tiap baris menentukan siapa yang
## bicara: "npc" memakai npc_talk_box, "mc" memakai mc_talk_box.
## Opsional per baris:
##   "choices": [{"text": "Yes", "goto": 3}, ...]  -> tampilkan pilihan jawaban
##   "end": true                                    -> percakapan selesai di baris ini
## Contoh:
##   var ui = get_node("/root/Main/GameUI")
##   ui.start_conversation([
##       {"who": "npc", "text": "Mau ikut?", "choices": [
##           {"text": "Ya", "goto": 1}, {"text": "Tidak", "goto": 2}]},
##       {"who": "npc", "text": "Bagus!", "end": true},
##       {"who": "npc", "text": "Sayang sekali.", "end": true},
##   ], "MALACHAR", "AELINDRA")
func start_conversation(lines: Array, npc_name: String = "MALACHAR", mc_name: String = "AELINDRA") -> void:
	_npc_box = _box_refs(get_tree().get_first_node_in_group("ui_npc_talk"))
	_mc_box = _box_refs(get_tree().get_first_node_in_group("ui_mc_talk"))
	if lines.is_empty() or (_npc_box.is_empty() and _mc_box.is_empty()):
		return
	if not _npc_box.is_empty() and _npc_box["name"]:
		_npc_box["name"].text = npc_name
	if not _mc_box.is_empty() and _mc_box["name"]:
		_mc_box["name"].text = mc_name
	_conversation = lines
	_page = 0
	_show_page()


func _box_refs(layer: Node) -> Dictionary:
	if layer == null:
		return {}
	var base := "Root/TalkPanel/Content/"
	var dots: Array = []
	for i in range(1, 5):
		dots.append(layer.get_node_or_null(base + "TextBox/BottomRow/PageDots/Page%d" % i))
	return {
		"layer": layer,
		"text": layer.get_node_or_null(base + "TextBox/DialogueText"),
		"name": layer.get_node_or_null(base + "SpeakerBox/SpeakerName"),
		"dots": dots,
	}


func _is_talking() -> bool:
	return not _current_box.is_empty() and _current_box["layer"].visible


func _on_interact() -> void:
	if not _is_talking():
		start_conversation(DEMO_CONVERSATION)
		return
	if _choices_open:
		return
	var text: Label = _current_box["text"]
	if text.visible_ratio < 1.0:
		# Lewati efek ketik, langsung tampilkan semua teks.
		if _tween:
			_tween.kill()
		text.visible_ratio = 1.0
		_on_line_finished()
		return
	var line: Dictionary = _conversation[_page]
	if line.get("end", false):
		_end_conversation()
		return
	_page += 1
	if _page >= _conversation.size():
		_end_conversation()
	else:
		_show_page()


func _show_page() -> void:
	var line: Dictionary = _conversation[_page]
	var box := _mc_box if line.get("who", "npc") == "mc" else _npc_box
	if box.is_empty():
		_end_conversation()
		return
	# Hanya satu kotak yang tampil pada satu waktu.
	for b in [_npc_box, _mc_box]:
		if not b.is_empty():
			b["layer"].visible = (b == box)
	_current_box = box
	var text: Label = box["text"]
	var content: String = line.get("text", "")
	text.text = content
	text.visible_ratio = 0.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(text, "visible_ratio", 1.0, maxf(0.3, content.length() * 0.03))
	_tween.finished.connect(_on_line_finished)
	var dots: Array = box["dots"]
	for i in dots.size():
		if dots[i]:
			dots[i].visible = i < _conversation.size()
			dots[i].color = DOT_ON if i == _page else DOT_OFF


func _on_line_finished() -> void:
	# Kalau baris ini punya pilihan jawaban, tampilkan setelah teks selesai diketik.
	if _current_box.is_empty() or _page >= _conversation.size():
		return
	var line: Dictionary = _conversation[_page]
	if line.has("choices") and not _choices_open:
		_show_choices(line["choices"])


func _show_choices(choices: Array) -> void:
	var layer := get_tree().get_first_node_in_group("ui_choice") as CanvasLayer
	if layer == null:
		# Belum dipasang di scene? Buat otomatis supaya tetap muncul.
		var scene := load(CHOICE_BOX_SCENE) as PackedScene
		if scene:
			layer = scene.instantiate() as CanvasLayer
			get_tree().current_scene.add_child(layer)
	if layer == null:
		push_warning("choice_box tidak ditemukan. Cek path CHOICE_BOX_SCENE: " + CHOICE_BOX_SCENE)
		return
	var base := "Root/ChoicePanel/Choices/"
	for i in range(1, 5):
		var b := layer.get_node_or_null(base + "Choice%d" % i) as Button
		if b == null:
			continue
		if not _choices_wired:
			b.pressed.connect(_on_choice_pressed.bind(i - 1))
		b.visible = i <= choices.size()
		if b.visible:
			b.text = "%d. %s" % [i, choices[i - 1].get("text", "")]
	_choices_wired = true
	_pending_choices = choices
	_choices_open = true
	layer.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close_choices() -> void:
	_choices_open = false
	var layer := get_tree().get_first_node_in_group("ui_choice") as CanvasLayer
	if layer:
		layer.visible = false


func _on_choice_pressed(index: int) -> void:
	if not _choices_open or index >= _pending_choices.size():
		return
	var choice: Dictionary = _pending_choices[index]
	_close_choices()
	choice_made.emit(index, choice.get("text", ""))
	if choice.has("goto"):
		_page = int(choice["goto"])
	else:
		_page += 1
	if _page >= _conversation.size():
		_end_conversation()
	else:
		_show_page()


func _end_conversation() -> void:
	_close_choices()
	for b in [_npc_box, _mc_box]:
		if not b.is_empty():
			b["layer"].visible = false
	_current_box = {}
