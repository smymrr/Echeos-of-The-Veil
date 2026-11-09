extends CanvasLayer
## HUD (hotbar 6 skill + bar MP). Pasang di node HUD (CanvasLayer). Berdiri sendiri.
##
## Untuk backend:
##   hud.skill_used.connect(func(index, cost): ...)   -> skill dipakai (MP sudah dikurangi)
##   hud.mp_changed.connect(func(mp, max_mp): ...)    -> MP berubah karena skill / set_mp()
##   hud.set_mp(100.0), hud.get_mp(), hud.spend_mp(30)

signal skill_used(index: int, cost: int)
signal mp_changed(mp: float, max_mp: float)

const GROUP := "ui_hud"
const SKILL_KEYS := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6]
const SKILL_COUNT := 6

## MP pulih per detik.
@export var mp_regen := 5.0
## Lama efek cooldown visual setelah skill dipakai (detik).
@export var cast_time := 0.6
## DEMO: damage ke Boss Bar tiap skill. Isi 0 kalau damage diurus game logic.
@export var demo_boss_damage := 60.0

var _frames: Array = []
var _cooldowns: Array = []
var _costs: Array = []
var _sel_style: StyleBox
var _norm_style: StyleBox
var _casting := false

var _mp_bar: ProgressBar
var _mp_value: Label
var _mp := 264.0


func _ready() -> void:
	add_to_group(GROUP)
	for i in range(1, SKILL_COUNT + 1):
		var base := "Root/HotbarPanel/Content/Body/Slots/Skill%d/Frame" % i
		_frames.append(get_node_or_null(base))
		_cooldowns.append(get_node_or_null(base + "/Cooldown"))
		_costs.append(get_node_or_null(base + "/CostLabel"))
	if _frames[0] and _frames[1]:
		_sel_style = _frames[0].get_theme_stylebox("panel")
		_norm_style = _frames[1].get_theme_stylebox("panel")

	var mp := "Root/CharacterPanel/Content/Body/MpRow/"
	_mp_bar = get_node_or_null(mp + "MpBar") as ProgressBar
	_mp_value = get_node_or_null(mp + "MpValue") as Label
	if _mp_bar:
		_mp = _mp_bar.value


func _process(delta: float) -> void:
	if get_tree().paused or _mp_bar == null:
		return
	_mp = minf(_mp + mp_regen * delta, _mp_bar.max_value)
	_update_mp()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if UiUtil.input_blocked(get_tree()):
		return
	var i := SKILL_KEYS.find(event.keycode)
	if i != -1:
		use_skill(i)


# ------------------------------------------------------------- API publik

func get_mp() -> float:
	return _mp


func set_mp(value: float) -> void:
	_mp = clampf(value, 0.0, _mp_bar.max_value if _mp_bar else value)
	_update_mp()
	mp_changed.emit(_mp, _mp_bar.max_value if _mp_bar else _mp)


## Kurangi MP. Return false kalau MP tidak cukup.
func spend_mp(cost: float) -> bool:
	if _mp < cost:
		return false
	set_mp(_mp - cost)
	return true


func get_skill_cost(index: int) -> int:
	if index < 0 or index >= _costs.size() or _costs[index] == null:
		return 0
	return int(_costs[index].text)


## index 0-5. Dipanggil oleh tombol 1-6, boleh juga dipanggil dari script lain.
func use_skill(index: int) -> void:
	if _casting or index < 0 or index >= _frames.size():
		return
	_select_skill(index)
	var cost := get_skill_cost(index)
	if not spend_mp(cost):
		return
	_casting = true
	if _cooldowns[index]:
		_cooldowns[index].visible = true
	skill_used.emit(index, cost)
	if demo_boss_damage > 0.0:
		get_tree().call_group("ui_boss", "take_damage", demo_boss_damage)
	await get_tree().create_timer(cast_time).timeout
	if _cooldowns[index]:
		_cooldowns[index].visible = false
	_casting = false


# ------------------------------------------------------------- Internal

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
