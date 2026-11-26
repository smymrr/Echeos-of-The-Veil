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
const DEFAULT_HP := 2000

var _hp: int = DEFAULT_HP
var _boss_name: String = "Wraith Sentinel"

@export var _name: Label
@export var _value: Label
@export var _bar: ProgressBar

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
	_hp = _bar.max_value if _bar else DEFAULT_HP
	refresh()

func take_damage(amount: int) -> void:
	if not visible:
		return
	_hp = max(0., _hp - amount)
	refresh()
	if _hp <= 0.0:
		visible = false
		boss_defeated.emit()

## Perbarui bar dan teks HP sesuai nilai `hp`.
func refresh(_method: String = "") -> void:
	if _name:
		_name.text = _boss_name
	if _value and _bar:
		if _method.to_lower() == "tween":
			var tween = create_tween().set_parallel(true)
			tween.tween_property(_bar, "value", _hp, 5)
			tween.tween_method(
				func(val: float): _value.text = "%d / %d" % [int(round(val)), int(_bar.max_value)],
					_bar.value, # Start value
					_hp,        # End value
					5.0         # Duration
				)
		else:
			_bar.value = _hp
			_value.text = "%d / %d" % [int(_hp), int(_bar.max_value)]

func set_boss_bar(boss_name: String, boss_hp: int, method: String = "") -> void:
	_boss_name = boss_name
	_hp = boss_hp
	_bar.max_value = _hp
	
	refresh(method)

func _choices_open() -> bool:
	var c := get_tree().get_first_node_in_group("ui_choice") as CanvasLayer
	return c != null and c.visible
