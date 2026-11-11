class_name ChoiceBox
extends CanvasLayer
## Kotak pilihan jawaban (2-4 tombol). Pasang di root scene choice_box.tscn.
## Dipilih dengan tombol 1-4 atau klik mouse.

## Dikirim saat pemain memilih (index mulai dari 0).
signal choice_selected(index: int)

const GROUP := "ui_choice"
const CHOICE_KEYS := [KEY_1, KEY_2, KEY_3, KEY_4]
const BASE := "Root/Choices/"

var _buttons: Array = []
var _count := 0


func _ready() -> void:
	add_to_group(GROUP)
	for i in range(1, 5):
		var b := get_node_or_null(BASE + "Choice%d" % i) as Button
		_buttons.append(b)
		if b:
			b.pressed.connect(func(): choice_selected.emit(i - 1))


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var c := CHOICE_KEYS.find(event.keycode)
	if c != -1 and c < _count:
		get_viewport().set_input_as_handled()
		choice_selected.emit(c)


## choices: [{"text": "Ya"}, {"text": "Tidak"}, ...]  (maksimal 4)
func show_choices(choices: Array) -> void:
	_count = mini(choices.size(), _buttons.size())
	for i in _buttons.size():
		var b: Button = _buttons[i]
		if b == null:
			continue
		# Hanya tampilkan sebanyak pilihan yang diberikan.
		b.visible = i < _count
		b.text = "%d. %s" % [i + 1, choices[i].get("text", "")] if b.visible else ""
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	_count = 0
	visible = false
