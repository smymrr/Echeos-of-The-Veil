class_name LoadingScreen
extends Control
## Memuat scene berikutnya di thread terpisah dan mengisi bar.
## Dipakai dari mana saja:  LoadingScreen.go_to(get_tree(), "res://scenes/main.tscn")
## Kalau scene ini dijalankan langsung (F6), progres dipalsukan supaya tampilannya bisa dites.

const SCENE_PATH := "res://scenes/ui/loading_screen.tscn"   # GANTI sesuai lokasi scene ini
static var next_scene_path: String = ""


static func go_to(tree: SceneTree, path: String) -> void:
	next_scene_path = path
	tree.change_scene_to_file(SCENE_PATH)

@onready var bar: ProgressBar = $ProgressBar

@export var min_show_time: float = 1.5       # tampil minimal sekian detik, supaya tidak cuma berkedip
@export var fill_speed: float = 0.7          # kecepatan bar mengejar progres asli (1.0 = penuh dalam 1 detik)
@export var fade_out_time: float = 0.4
@export var preview_duration: float = 4.0    # lama progres palsu kalau scene dijalankan langsung

var _elapsed := 0.0
var _shown := 0.0
var _packed: PackedScene
var _finishing := false


func _ready() -> void:
	if next_scene_path != "":
		var err := ResourceLoader.load_threaded_request(next_scene_path)
		if err != OK:
			push_error("Tidak bisa memuat: " + next_scene_path)


func _process(delta: float) -> void:
	if _finishing:
		return
	_elapsed += delta
	_shown = move_toward(_shown, _get_real_progress(), fill_speed * delta)
	bar.value = _shown

	if _shown >= 1.0 and _elapsed >= min_show_time:
		_finish()


func _get_real_progress() -> float:
	if next_scene_path == "":
		return clampf(_elapsed / preview_duration, 0.0, 1.0)   # mode preview
	if _packed != null:
		return 1.0

	var progress: Array = []
	match ResourceLoader.load_threaded_get_status(next_scene_path, progress):
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			return progress[0] if progress.size() > 0 else 0.0
		ResourceLoader.THREAD_LOAD_LOADED:
			_packed = ResourceLoader.load_threaded_get(next_scene_path) as PackedScene
			return 1.0
		_:
			push_error("Gagal memuat: " + next_scene_path)
			set_process(false)
	return 0.0


func _finish() -> void:
	if _packed == null:
		return   # mode preview: berhenti di 100%
	_finishing = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_out_time)
	await tween.finished
	get_tree().change_scene_to_packed(_packed)
