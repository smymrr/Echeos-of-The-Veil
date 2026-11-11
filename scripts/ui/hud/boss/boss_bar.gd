extends CanvasLayer
## Boss Bar STANDALONE. Pasang script ini di root scene boss_bar.tscn (CanvasLayer).
## Tidak butuh GameUI: tombol F1 dan logika HP ada di sini.
##
## Cara memberi damage dari script mana pun (tanpa referensi langsung):
##   get_tree().call_group("ui_boss", "take_damage", 60.0)
## Atau kalau punya referensinya:  boss_bar.take_damage(60.0)

## Dikirim saat HP bos habis.
signal boss_defeated

const GROUP := "ui_boss"
const DEFAULT_HP := 2000.0

var hp := DEFAULT_HP

@onready var _bar := get_node_or_null("Root/BossGroup/BossBar") as ProgressBar
@onready var _value := get_node_or_null("Root/BossGroup/BossHpValue") as Label


func _ready() -> void:
	add_to_group(GROUP)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode != KEY_F1:
		return
	if get_tree().paused or _choices_open():
		return
	toggle()


## Tampil/sembunyi. Saat tampil, HP direset penuh.
func toggle() -> void:
	visible = not visible
	if visible:
		reset_hp()


func reset_hp() -> void:
	hp = _bar.max_value if _bar else DEFAULT_HP
	refresh()


func take_damage(amount: float) -> void:
	if not visible:
		return
	hp = maxf(0.0, hp - amount)
	refresh()
	if hp <= 0.0:
		visible = false
		boss_defeated.emit()


## Perbarui bar dan teks HP sesuai nilai `hp`.
func refresh() -> void:
	if _bar:
		_bar.value = hp
	if _value and _bar:
		_value.text = "%d / %d" % [int(hp), int(_bar.max_value)]


func _choices_open() -> bool:
	var c := get_tree().get_first_node_in_group("ui_choice") as CanvasLayer
	return c != null and c.visible
