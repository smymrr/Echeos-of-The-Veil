class_name OptionsPanel
extends CanvasLayer
## Panel Options di dalam game. Pasang di root scene options_ingame.tscn.
## Dibuka oleh PauseMenu (group "ui_options").

const GROUP := "ui_options"
const TAB_NAMES := ["AudioTab", "DisplayTab", "GameplayTab"]

## Harus lebih tinggi dari layer PauseMenu supaya tampil di atasnya.
@export var min_layer := 110


func _ready() -> void:
	add_to_group(GROUP)
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = maxi(layer, min_layer)
	var back := get_node_or_null("Root/Panel/Content/BackButton") as Button
	if back:
		back.pressed.connect(close)
	_wire_tabs()


func open() -> void:
	visible = true
	get_tree().call_group("ui_pause", "show_menu", false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	visible = false
	get_tree().call_group("ui_pause", "show_menu", true)


## Dipanggil PauseMenu saat ESC. Return true kalau ESC dipakai.
func handle_escape() -> bool:
	if visible:
		close()
		return true
	return false


## Angka persen slider. Sambungkan: slider.value_changed.connect(on_slider_changed.bind(label))
func on_slider_changed(value: float, lbl: Label) -> void:
	lbl.text = "%d%%" % int(value)


## Tab kiri (Audio / Display / Gameplay) mengganti halaman di node Pages.
func _wire_tabs() -> void:
	var pages_root := get_node_or_null("Root/Panel/Content/Body/Pages")
	if pages_root == null:
		push_warning("Options: node Pages tidak ditemukan")
		return
	var pages: Array = pages_root.get_children()
	for i in TAB_NAMES.size():
		var tab := find_child(TAB_NAMES[i], true, false) as BaseButton
		if tab:
			tab.pressed.connect(_show_page.bind(pages, i))
	_show_page(pages, 0)


func _show_page(pages: Array, index: int) -> void:
	for i in pages.size():
		pages[i].visible = (i == index)
