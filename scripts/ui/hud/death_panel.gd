class_name DeathPanel
extends CanvasLayer
## Panel kematian ("YOU HAVE FALLEN"). Scene mandiri, mengikuti pola panel lain:
## masuk group "ui_death", dipanggil lewat group, dan ESC ditangani PauseMenu.
##
## Dipanggil dari mana saja (player, boss, game_ui, dll):
##   get_tree().call_group("ui_death", "show_death", "Wraith Sentinel", 91.0, 1240, 2000)
##   get_tree().call_group("ui_death", "show_death")        # tanpa info musuh
##
## RETRY  -> memuat ulang scene yang sedang berjalan
## EXIT   -> pindah ke main menu
## Kalau mau diurus backend sendiri (checkpoint, dll), matikan auto_handle dan
## sambungkan sinyal retry_requested / main_menu_requested.

const GROUP := "ui_death"

signal retry_requested
signal main_menu_requested

## Scene main menu tujuan tombol EXIT.
@export_file("*.tscn") var main_menu_scene: String = "res://scenes/ui/main_menu.tscn"
## true: tombol langsung reload scene / ke main menu. false: hanya mengirim sinyal.
@export var auto_handle: bool = true
## Pause game selama panel tampil.
@export var pause_game: bool = true
## Lama fade-in (detik).
@export var fade_time: float = 0.6

@onready var _root: Control = $Root
@onready var _message: Label = $Root/Center/Card/Content/MessageLabel
@onready var _left_name: Label = $Root/Center/Card/Content/StatsRow/LeftStat/LeftName
@onready var _left_value: Label = $Root/Center/Card/Content/StatsRow/LeftStat/LeftValue
@onready var _right_stat: Control = $Root/Center/Card/Content/StatsRow/RightStat
@onready var _right_name: Label = $Root/Center/Card/Content/StatsRow/RightStat/RightName
@onready var _right_value: Label = $Root/Center/Card/Content/StatsRow/RightStat/RightValue
@onready var _retry: Button = $Root/Center/Card/Content/RetryButton
@onready var _exit: Button = $Root/Center/Card/Content/ExitButton


func _ready() -> void:
	add_to_group(GROUP)
	process_mode = Node.PROCESS_MODE_ALWAYS  # tombol tetap jalan saat game di-pause
	visible = false
	_retry.pressed.connect(_on_retry)
	_exit.pressed.connect(_on_exit)


func show_death(
		killer_name: String = "",
		battle_time: float = -1.0,
		enemy_hp: float = -1.0,
		enemy_max_hp: float = -1.0) -> void:
	if killer_name != "":
		_message.text = "The %s tears your echo from the mortal realm." % killer_name
	_left_name.text = "BATTLE TIME"
	_left_value.text = _format_time(battle_time) if battle_time >= 0.0 else "--:--"
	_right_stat.visible = enemy_hp >= 0.0
	if enemy_hp >= 0.0:
		_right_name.text = "ENEMY HP"
		_right_value.text = "%d / %d" % [int(enemy_hp), int(enemy_max_hp)]

	visible = true
	if pause_game:
		get_tree().paused = true
	_root.modulate.a = 0.0
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_root, "modulate:a", 1.0, fade_time)
	_retry.grab_focus()


## Dipanggil PauseMenu saat ESC: menelan ESC selama panel kematian tampil,
## sehingga Pause tidak terbuka di atasnya.
func handle_escape() -> bool:
	return visible


func hide_death() -> void:
	visible = false
	if pause_game:
		get_tree().paused = false


func _on_retry() -> void:
	retry_requested.emit()
	if not auto_handle:
		return
	hide_death()
	get_tree().reload_current_scene()


func _on_exit() -> void:
	main_menu_requested.emit()
	if not auto_handle:
		return
	if not ResourceLoader.exists(main_menu_scene):
		push_error("DeathPanel: main_menu_scene tidak ditemukan: " + main_menu_scene)
		return
	hide_death()
	get_tree().change_scene_to_file(main_menu_scene)


func _format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d" % [total / 60, total % 60]
