class_name PauseMenu
extends CanvasLayer
## Menu Pause. Pasang di node PausePanel (CanvasLayer).
## Juga pemilik tombol ESC: menutup lapisan paling atas dulu (Save -> Options ->
## konfirmasi Quit -> Inventory), baru buka/tutup Pause.
##
## Backend:
##   pause_menu.load_requested.connect(func(): ...)   -> tombol Load ditekan
##   pause_menu.game_paused / game_resumed

signal game_paused
signal game_resumed
signal load_requested

const GROUP := "ui_pause"
## Panel yang ditutup lebih dulu saat ESC (masing-masing punya handle_escape()).
const ESC_BEFORE_CONFIRM := ["ui_save", "ui_options"]
const ESC_AFTER_CONFIRM := ["ui_inventory"]

## Pause selalu digambar di atas panel lain (layer terendah yang dipakai).
@export var min_layer := 100
## Cetak status ke panel Output setiap kali Pause dibuka/ditutup (matikan kalau sudah beres).
@export var debug_log := true
@export_file("*.tscn") var main_menu_scene := "res://scenes/ui/main_menu.tscn"
@export_file("*.tscn") var options_scene := "res://scenes/options_ingame.tscn"
@export_file("*.tscn") var save_scene := "res://scenes/save_panel.tscn"

@onready var _menu := get_node_or_null("Root/PausePanel") as Control
@onready var _confirm := get_node_or_null("Root/ConfirmPanel") as Control


func _ready() -> void:
	add_to_group(GROUP)
	# Supaya input tetap diterima saat game di-pause.
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = maxi(layer, min_layer)
	visible = false  # tersembunyi sampai Pause dibuka, tidak bergantung pada pengaturan instance

	_connect_button("ResumeButton", toggle)
	_connect_button("SaveButton", func(): _open_panel("ui_save", save_scene))
	_connect_button("LoadButton", func(): load_requested.emit())
	_connect_button("OptionsButton", func(): _open_panel("ui_options", options_scene))
	_connect_button("MainMenuButton", go_main_menu)
	_connect_button("QuitButton", show_quit_confirm)
	_connect_confirm("YesButton", go_main_menu)
	_connect_confirm("NoButton", hide_quit_confirm)


	if _menu == null:
		push_warning("PauseMenu: node 'Root/PausePanel' tidak ditemukan. Cek nama node di pause_panel.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_ESCAPE:
		_handle_escape()


func toggle() -> void:
	var pausing := not get_tree().paused
	get_tree().paused = pausing
	visible = pausing
	if pausing:
		_reset_view()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		game_paused.emit()
	else:
		hide_quit_confirm()
		get_tree().call_group("ui_options", "close")
		get_tree().call_group("ui_save", "close")
		game_resumed.emit()
	if debug_log:
		_log_state()


func _log_state() -> void:
	var root := get_node_or_null("Root") as CanvasItem
	print("[PauseMenu] paused=%s | layer=%d | visible=%s | Root=%s | Menu=%s" % [
		get_tree().paused, layer, visible,
		str(root.visible) if root else "tidak ada",
		str(_menu.visible) if _menu else "tidak ada",
	])


## Pastikan menu utama (bukan konfirmasi) tampil setiap kali Pause dibuka,
## walaupun node di dalamnya tersembunyi di editor.
func _reset_view() -> void:
	var root := get_node_or_null("Root") as CanvasItem
	if root:
		root.visible = true
	if _confirm:
		_confirm.visible = false
	show_menu(true)


## Dipanggil Options/Save lewat group untuk menyembunyikan/menampilkan tombol Pause.
func show_menu(is_shown: bool) -> void:
	if _menu:
		_menu.visible = is_shown


func show_quit_confirm() -> void:
	if _confirm:
		_confirm.visible = true
	show_menu(false)


func hide_quit_confirm() -> void:
	if _confirm:
		_confirm.visible = false
	show_menu(true)


func go_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(main_menu_scene)


func _handle_escape() -> void:
	if _close_top(ESC_BEFORE_CONFIRM):
		return
	if _confirm and _confirm.visible:
		hide_quit_confirm()
		return
	if _close_top(ESC_AFTER_CONFIRM):
		return
	toggle()


func _close_top(groups: Array) -> bool:
	for g in groups:
		var n := get_tree().get_first_node_in_group(g)
		if n and n.has_method("handle_escape") and n.handle_escape():
			return true
	return false


## Buka panel (Save/Options) lewat group. Kalau belum ada di scene, dibuat dari file scene.
func _open_panel(group: String, scene_path: String) -> void:
	var p := get_tree().get_first_node_in_group(group)
	if p == null:
		var scene := load(scene_path) as PackedScene
		if scene:
			p = scene.instantiate()
			get_parent().add_child(p)
	if p == null:
		push_warning("Panel '%s' tidak ditemukan. Cek path: %s" % [group, scene_path])
		return
	p.open()


func _connect_button(button_name: String, action: Callable) -> void:
	var b := get_node_or_null("Root/PausePanel/Content/ButtonList/" + button_name) as Button
	if b:
		b.pressed.connect(action)


func _connect_confirm(button_name: String, action: Callable) -> void:
	var b := get_node_or_null("Root/ConfirmPanel/Content/Buttons/" + button_name) as Button
	if b:
		b.pressed.connect(action)
