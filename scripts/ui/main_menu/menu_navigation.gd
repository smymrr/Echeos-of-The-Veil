extends CanvasItem

## Dikirim saat New Journey benar-benar dimulai.
## slot = 0 -> pakai slot kosong, slot > 0 -> slot yang dipilih pemain untuk ditimpa.
## Koder: hapus / timpa save di slot itu lewat sinyal ini sebelum scene game dibuka.
signal new_journey_started(slot: int)

@export_group("Tombol Menu")
@export var new_journey_button: NodePath
@export var load_data_button: NodePath
@export var synopsis_button: NodePath
@export var options_button: NodePath
@export var exit_button: NodePath

@export_group("Screen / Panel Tujuan")
@export var new_journey_screen: NodePath
@export var load_data_screen: NodePath
@export var synopsis_screen: NodePath
@export var options_screen: NodePath
@export var exit_screen: NodePath

@export_group("Fade Settings")
@export var fade_duration: float = 0.25

@export_group("New Journey")
## Scene game yang dibuka saat New Journey dimulai.
@export_file("*.tscn") var new_journey_scene: String = "res://scenes/main.tscn"
## PREVIEW: true = anggap semua slot save penuh, jadi panel "pilih slot yang ditimpa" muncul.
## false = New Journey langsung mulai. Koder: ganti dengan pengecekan save asli di _are_slots_full().
@export var preview_slots_full: bool = true

var _screens: Array[Control] = []
var _buttons: Array[Control] = []
var _fade_tween: Tween
var _nj_screen: Control
var _overwrite_slot := 0


func _ready() -> void:
	# New Journey ditangani terpisah (bisa langsung mulai, atau membuka panel pilih slot).
	var pairs := [
		[load_data_button, load_data_screen],
		[synopsis_button, synopsis_screen],
		[options_button, options_screen],
		[exit_button, exit_screen],
	]

	for pair in pairs:
		var btn: BaseButton = get_node_or_null(pair[0]) as BaseButton
		var screen: Control = get_node_or_null(pair[1]) as Control

		if btn:
			_buttons.append(btn)

		if screen:
			screen.visible = false
			screen.modulate.a = 0.0
			_screens.append(screen)
			_connect_back_button(screen)

		if btn and screen:
			btn.pressed.connect(_show_screen.bind(screen))
		elif btn == null and pair[0] != NodePath():
			push_warning("Tombol tidak ditemukan: %s" % pair[0])
		elif screen == null and pair[1] != NodePath():
			push_warning("Screen tidak ditemukan: %s" % pair[1])

	# New Journey
	var nj_btn: BaseButton = get_node_or_null(new_journey_button) as BaseButton
	_nj_screen = get_node_or_null(new_journey_screen) as Control
	if nj_btn:
		_buttons.append(nj_btn)
		nj_btn.pressed.connect(_on_new_journey_pressed)
	if _nj_screen:
		_nj_screen.visible = false
		_nj_screen.modulate.a = 0.0
		_screens.append(_nj_screen)
		_connect_back_button(_nj_screen)
		_connect_new_journey_screen(_nj_screen)

	var exit_scr: Control = get_node_or_null(exit_screen) as Control
	if exit_scr:
		var yes_btn := _find_node_by_name(exit_scr, "YesButton")
		if yes_btn and yes_btn is BaseButton:
			yes_btn.pressed.connect(_on_exit_pressed)
		else:
			push_warning("YesButton tidak ditemukan di ExitScreen")


func _set_menu_interactive(state: bool) -> void:
	var filter := Control.MOUSE_FILTER_STOP if state else Control.MOUSE_FILTER_IGNORE
	for b in _buttons:
		b.mouse_filter = filter


func _show_screen(screen: Control) -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	_set_menu_interactive(false)  # langsung matiin interaksi, jangan tunggu fade kelar

	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_SINE)
	_fade_tween.set_ease(Tween.EASE_OUT)

	# fade out MenuPanel DAN semua tombolnya bareng-bareng
	_fade_tween.set_parallel(true)
	_fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	for b in _buttons:
		_fade_tween.tween_property(b, "modulate:a", 0.0, fade_duration)
	_fade_tween.set_parallel(false)

	_fade_tween.tween_callback(func():
		visible = false
		for b in _buttons:
			b.visible = false
		for s in _screens:
			if s != screen:
				s.visible = false
				s.modulate.a = 0.0
	)

	_fade_tween.tween_callback(func():
		screen.visible = true
	)
	_fade_tween.tween_property(screen, "modulate:a", 1.0, fade_duration)


func show_menu() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	var current_screen: Control = null
	for s in _screens:
		if s.visible:
			current_screen = s
			break

	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_SINE)
	_fade_tween.set_ease(Tween.EASE_OUT)

	if current_screen:
		_fade_tween.tween_property(current_screen, "modulate:a", 0.0, fade_duration)
		_fade_tween.tween_callback(func():
			current_screen.visible = false
			visible = true
			modulate.a = 0.0
			for b in _buttons:
				b.visible = true
				b.modulate.a = 0.0
		)
	else:
		_fade_tween.tween_callback(func():
			visible = true
			modulate.a = 0.0
			for b in _buttons:
				b.visible = true
				b.modulate.a = 0.0
		)

	_fade_tween.set_parallel(true)
	_fade_tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	for b in _buttons:
		_fade_tween.tween_property(b, "modulate:a", 1.0, fade_duration)
	_fade_tween.set_parallel(false)

	_fade_tween.tween_callback(func():
		_set_menu_interactive(true)
	)


# ------------------------------------------------------------------ New Journey
## Koder: ganti isinya dengan pengecekan save yang asli
## (misalnya hitung file save, lalu return jumlah >= batas slot).
func _are_slots_full() -> bool:
	return preview_slots_full


func _on_new_journey_pressed() -> void:
	if _nj_screen and _are_slots_full():
		_set_overwrite_confirm(false)
		_show_screen(_nj_screen)
	else:
		_start_new_journey(0)


func _connect_new_journey_screen(screen: Control) -> void:
	for i in range(1, 6):
		var slot := _find_node_by_name(screen, "Slot%d" % i) as BaseButton
		if slot:
			slot.pressed.connect(_on_overwrite_slot_pressed.bind(i))
	var yes := _find_node_by_name(screen, "YesButton") as BaseButton
	var no := _find_node_by_name(screen, "NoButton") as BaseButton
	if yes:
		yes.pressed.connect(_on_overwrite_confirmed)
	if no:
		no.pressed.connect(_set_overwrite_confirm.bind(false))
	_wire_screen_sounds(screen)


func _on_overwrite_slot_pressed(index: int) -> void:
	_overwrite_slot = index
	var text := _find_node_by_name(_nj_screen, "ConfirmText1") as Label
	if text:
		text.text = "Overwrite Slot %d?" % index
	_set_overwrite_confirm(true)


func _set_overwrite_confirm(show: bool) -> void:
	if _nj_screen == null:
		return
	var layer := _find_node_by_name(_nj_screen, "ConfirmLayer") as Control
	if layer:
		layer.visible = show


func _on_overwrite_confirmed() -> void:
	_set_overwrite_confirm(false)
	_start_new_journey(_overwrite_slot)


func _start_new_journey(slot: int = 0) -> void:
	new_journey_started.emit(slot)
	_set_menu_interactive(false)
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_SINE)
	_fade_tween.set_ease(Tween.EASE_OUT)

	# menu memudar dulu, baru pindah ke scene game
	_fade_tween.set_parallel(true)
	_fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	for b in _buttons:
		_fade_tween.tween_property(b, "modulate:a", 0.0, fade_duration)
	if _nj_screen and _nj_screen.visible:
		_fade_tween.tween_property(_nj_screen, "modulate:a", 0.0, fade_duration)
	_fade_tween.set_parallel(false)

	_fade_tween.tween_callback(func():
		get_tree().change_scene_to_file(new_journey_scene)
	)


## Suara hover / klik / back untuk tombol di panel baru, memakai node HoverSound,
## ClickSound, dan BackSound yang sudah ada di scene main menu.
func _wire_screen_sounds(screen: Control) -> void:
	var root := get_parent()
	if root == null:
		return
	var hover := root.get_node_or_null("HoverSound") as AudioStreamPlayer
	var click := root.get_node_or_null("ClickSound") as AudioStreamPlayer
	var back := root.get_node_or_null("BackSound") as AudioStreamPlayer
	for node in screen.find_children("*", "BaseButton", true, false):
		var button := node as BaseButton
		if hover:
			button.mouse_entered.connect(hover.play)
		var player := back if (button.name == &"BackButton" or button.name == &"NoButton") else click
		if player:
			button.pressed.connect(player.play)


func _on_exit_pressed() -> void:
	get_tree().quit()


func _connect_back_button(screen: Control) -> void:
	var back_btn := _find_node_by_name(screen, "BackButton")
	if back_btn and back_btn is BaseButton:
		back_btn.pressed.connect(show_menu)


func _find_node_by_name(node: Node, target_name: String) -> Node:
	for child in node.get_children():
		if child.name == target_name:
			return child
		var found := _find_node_by_name(child, target_name)
		if found:
			return found
	return null
