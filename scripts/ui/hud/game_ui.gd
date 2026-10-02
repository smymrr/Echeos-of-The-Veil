extends Node
## Script demo supaya semua UI bisa dicoba. Isinya hanya urusan tampil/sembunyi
## dan efek sederhana. Programmer boleh mengganti dengan logika game yang asli.
##
## Kontrol:
##   ESC      = buka/tutup Pause
##   J        = buka/tutup Quest
##   E        = bicara (tekan lagi untuk lanjut / lewati ketikan)
##   1 - 6    = pakai skill (MP berkurang, bos terkena damage kalau tampil)
##   F1       = tampil/sembunyi Boss Bar
##   F2       = tampil/sembunyi Wave Panel
##   F3       = minimize / buka semua panel sekaligus (tanpa mouse)

const DOT_ON := Color(0.48, 0.35, 0.82)
const DOT_OFF := Color(0.25, 0.19, 0.48)
const SKILL_KEYS := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6]
const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"
const DEMO_LINES := [
	"You dare enter my sanctum, Veilwalker?",
	"The Veil has been waiting for you.",
	"Turn back now, or be forgotten.",
]

var _quest: CanvasLayer
var _boss: CanvasLayer
var _wave: CanvasLayer
var _talk: CanvasLayer
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

var _boss_bar: ProgressBar
var _boss_value: Label
var _boss_hp := 2000.0

var _talk_text: Label
var _talk_name: Label
var _dots: Array = []
var _lines: Array = []
var _page := 0
var _tween: Tween


func _ready() -> void:
	# Supaya input tetap diterima saat game di-pause.
	process_mode = Node.PROCESS_MODE_ALWAYS

	_quest = get_node_or_null("QuestLog")
	_boss = get_node_or_null("BossBar")
	_wave = get_node_or_null("WavePanel")
	_talk = get_node_or_null("TalkBox")
	_pause = get_node_or_null("PausePanel")

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
	var cb := "HUD/Root/CharacterPanel/Content/Body/MpRow/"
	_mp_bar = get_node_or_null(cb + "MpBar")
	_mp_value = get_node_or_null(cb + "MpHeader/MpValue")
	if _mp_bar:
		_mp = _mp_bar.value

	# Bar Boss
	var bb := "BossBar/Root/BossPanel/Content/"
	_boss_bar = get_node_or_null(bb + "BossBar")
	_boss_value = get_node_or_null(bb + "Footer/BossHpValue")

	# Talk box
	var tb := "TalkBox/Root/TalkPanel/Content/"
	_talk_text = get_node_or_null(tb + "TextBox/DialogueText")
	_talk_name = get_node_or_null(tb + "SpeakerBox/SpeakerName")
	for i in range(1, 5):
		_dots.append(get_node_or_null(tb + "TextBox/BottomRow/PageDots/Page%d" % i))

	# Tombol Pause
	_connect_button("ResumeButton", toggle_pause)
	_connect_button("SaveButton", func(): print("SAVE: sambungkan ke sistem save"))
	_connect_button("LoadButton", func(): print("LOAD: sambungkan ke sistem load"))
	_connect_button("OptionsButton", func(): print("OPTIONS: tampilkan panel Options"))
	_connect_button("MainMenuButton", _go_main_menu)
	_connect_button("QuitButton", func(): get_tree().quit())


func _connect_button(button_name: String, action: Callable) -> void:
	var path := "PausePanel/Root/PausePanel/Content/ButtonList/" + button_name
	var b := get_node_or_null(path) as Button
	if b:
		b.pressed.connect(action)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key: int = event.keycode
	if key == KEY_ESCAPE:
		toggle_pause()
		return
	if get_tree().paused:
		return
	match key:
		KEY_J:
			_toggle(_quest)
		KEY_E:
			_on_interact()
		KEY_F1:
			_toggle_boss()
		KEY_F2:
			_toggle(_wave)
		KEY_F3:
			_toggle_all_minimize()
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
	if pausing:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _go_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


# ------------------------------------------------------------ Tampil/sembunyi
func _toggle(layer: CanvasLayer) -> void:
	if layer:
		layer.visible = not layer.visible


func _toggle_boss() -> void:
	if _boss == null:
		return
	_boss.visible = not _boss.visible
	if _boss.visible:
		_boss_hp = _boss_bar.max_value if _boss_bar else 2000.0
		_update_boss()


func _toggle_all_minimize() -> void:
	var buttons: Array = []
	for layer in [get_node_or_null("HUD"), _quest, _wave]:
		if layer:
			buttons.append_array(layer.find_children("MinimizeButton", "Button", true, false))
	if buttons.is_empty():
		return
	var minimize: bool = not buttons[0].button_pressed
	for b in buttons:
		b.button_pressed = minimize


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
	# Kalau Boss Bar sedang tampil, skill memberi damage.
	if _boss and _boss.visible:
		_boss_hp = maxf(0.0, _boss_hp - 60.0)
		_update_boss()
		if _boss_hp <= 0.0:
			_boss.visible = false
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


func _update_boss() -> void:
	if _boss_bar:
		_boss_bar.value = _boss_hp
	if _boss_value and _boss_bar:
		_boss_value.text = "%d / %d" % [int(_boss_hp), int(_boss_bar.max_value)]


# ---------------------------------------------------------------- Dialog
## Panggil dari NPC atau musuh yang bisa bicara, contoh:
##   get_node("/root/Main/GameUI").start_talk("MALACHAR", ["Halo.", "Selamat datang."])
func start_talk(speaker: String, lines: Array) -> void:
	if _talk == null or _talk_text == null or lines.is_empty():
		return
	_lines = lines
	_page = 0
	if _talk_name:
		_talk_name.text = speaker
	_talk.visible = true
	_show_page()


func _on_interact() -> void:
	if _talk == null:
		return
	if not _talk.visible:
		start_talk("MALACHAR", DEMO_LINES)
	elif _talk_text.visible_ratio < 1.0:
		# Lewati efek ketik, langsung tampilkan semua teks.
		if _tween:
			_tween.kill()
		_talk_text.visible_ratio = 1.0
	else:
		_page += 1
		if _page >= _lines.size():
			_talk.visible = false
		else:
			_show_page()


func _show_page() -> void:
	var line: String = _lines[_page]
	_talk_text.text = line
	_talk_text.visible_ratio = 0.0
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_talk_text, "visible_ratio", 1.0, maxf(0.3, line.length() * 0.03))
	for i in _dots.size():
		if _dots[i]:
			_dots[i].visible = i < _lines.size()
			_dots[i].color = DOT_ON if i == _page else DOT_OFF
