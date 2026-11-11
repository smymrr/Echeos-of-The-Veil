class_name SavePanel
extends CanvasLayer
## Panel Save Game (5 slot). Pasang di root scene save_panel.tscn.
## Dibuka oleh PauseMenu (group "ui_save").
##
## Backend (slot mulai dari 1):
##   save_panel.save_requested.connect(func(slot): ...)
## Sebaiknya letakkan SavePanel di scene (bukan dibuat otomatis) supaya bisa disambungkan
## sejak awal.

signal save_requested(slot: int)

const GROUP := "ui_save"
const SLOT_COUNT := 5
const SLOT_PATH := "Root/Panel/Content/Scroll/Margin/SlotList/Slot%d"
const CONFIRM_BASE := "Root/ConfirmLayer/ConfirmPanel/Content/"

## Harus lebih tinggi dari layer PauseMenu supaya tampil di atasnya.
@export var min_layer := 110

var _slot := 0

@onready var _confirm_layer := get_node_or_null("Root/ConfirmLayer") as Control
@onready var _toast := get_node_or_null("Root/SavedToast") as Label


func _ready() -> void:
	add_to_group(GROUP)
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = maxi(layer, min_layer)

	var back := get_node_or_null("Root/Panel/Content/BackButton") as Button
	if back:
		back.pressed.connect(close)
	for i in range(1, SLOT_COUNT + 1):
		var slot := get_node_or_null(SLOT_PATH % i) as Button
		if slot:
			slot.pressed.connect(_on_slot_pressed.bind(i))
	var yes := get_node_or_null(CONFIRM_BASE + "Buttons/YesButton") as Button
	var no := get_node_or_null(CONFIRM_BASE + "Buttons/NoButton") as Button
	if yes:
		yes.pressed.connect(_confirm_save)
	if no:
		no.pressed.connect(_set_confirm.bind(false))


func open() -> void:
	visible = true
	_set_confirm(false)
	get_tree().call_group("ui_pause", "show_menu", false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	visible = false
	_set_confirm(false)
	get_tree().call_group("ui_pause", "show_menu", true)


## Dipanggil PauseMenu saat ESC. Menutup konfirmasi dulu, baru panel.
func handle_escape() -> bool:
	if _confirm_layer and _confirm_layer.visible:
		_set_confirm(false)
		return true
	if visible:
		close()
		return true
	return false


func _set_confirm(is_shown: bool) -> void:
	if _confirm_layer:
		_confirm_layer.visible = is_shown


func _on_slot_pressed(index: int) -> void:
	_slot = index
	var empty := get_node_or_null((SLOT_PATH % index) + "/EmptyLabel") as Label
	var is_empty := empty != null and empty.visible
	var line1 := get_node_or_null(CONFIRM_BASE + "ConfirmText1") as Label
	var line2 := get_node_or_null(CONFIRM_BASE + "ConfirmText2") as Label
	if line1:
		line1.text = "Save to Slot %d?" % index
	if line2:
		line2.text = "A new save will be created in this slot." if is_empty else "This will overwrite the existing save."
	_set_confirm(true)


func _confirm_save() -> void:
	_set_confirm(false)
	save_requested.emit(_slot)
	if _toast:
		_toast.text = "GAME SAVED  -  SLOT %d" % _slot
		_toast.visible = true
		await get_tree().create_timer(1.5).timeout
		_toast.visible = false
