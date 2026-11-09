extends CanvasLayer
## Panel Inventory STANDALONE. Pasang di node InventoryPanel (CanvasLayer).
## Tombol I dan tombol Close ditangani di sini. ESC dipanggil PauseMenu lewat
## handle_escape() (group "ui_inventory").
##
## Backend:  inventory.slot_selected.connect(func(index): ...)

signal slot_selected(index: int)

const GROUP := "ui_inventory"
const SLOT_COUNT := 20
const BASE := "Root/InvPanel/Content/"

var _info: Label


func _ready() -> void:
	add_to_group(GROUP)
	_info = get_node_or_null(BASE + "ItemInfo") as Label

	var close_btn := get_node_or_null(BASE + "HeaderRow/CloseButton") as Button
	if close_btn:
		close_btn.pressed.connect(close)

	for i in range(1, SLOT_COUNT + 1):
		var slot := get_node_or_null(BASE + "Grid/Slot%d" % i) as Button
		if slot:
			slot.pressed.connect(_on_slot_pressed.bind(i))


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_I and not UiUtil.input_blocked(get_tree()):
		toggle()


func toggle() -> void:
	visible = not visible
	if visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	visible = false


## Dipanggil PauseMenu saat ESC. Return true kalau ESC dipakai (panel ditutup).
func handle_escape() -> bool:
	if visible:
		close()
		return true
	return false


func set_info(text: String) -> void:
	if _info:
		_info.text = text


func _on_slot_pressed(index: int) -> void:
	set_info("Slot %d: (empty)" % index)
	slot_selected.emit(index)
