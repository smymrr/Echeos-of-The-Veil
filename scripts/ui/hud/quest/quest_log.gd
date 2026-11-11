extends CanvasLayer
## Quest Log. Pasang di node QuestLog (CanvasLayer). Tombol J buka/tutup.
## Isi quest sendiri diatur lewat scene/skrip backend; script ini hanya tampil/sembunyi.

const GROUP := "ui_quest"


func _ready() -> void:
	add_to_group(GROUP)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_J and not UiUtil.input_blocked(get_tree()):
		toggle()


func toggle() -> void:
	visible = not visible


func open() -> void:
	visible = true


func close() -> void:
	visible = false
