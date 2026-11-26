extends Control  # sesuaikan tipe node LoadDataScreen kamu (Control/Panel/Node2D)

@export var fade_duration: float = 0.25
@export_file("*.tscn") var game_scene: String = "res://scenes/main.tscn"

@onready var slot_list: VBoxContainer = $ScrollContainer/SlotList

var _fade_tween: Tween


func _ready() -> void:
	# Pastikan panel siap untuk fade, mulai dari transparan & tersembunyi
	modulate.a = 0.0
	visible = false

	visibility_changed.connect(_on_visibility_changed)
	refresh_slots()


func show_panel() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	refresh_slots()
	visible = true
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 1.0, fade_duration)


func hide_panel() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	await _fade_tween.finished
	visible = false


func _on_visibility_changed() -> void:
	if visible:
		refresh_slots()


func refresh_slots() -> void:
	var slots := slot_list.get_children()
	for i in range(slots.size()):
		var slot_node := slots[i] as LoadSlot
		if slot_node == null:
			continue

		var slot_index := i + 1
		var data := _read_slot_data(slot_index)
		slot_node.setup(slot_index, data)

		if not slot_node.slot_selected.is_connected(_on_slot_selected):
			slot_node.slot_selected.connect(_on_slot_selected)


func _read_slot_data(slot_index: int) -> Dictionary:
	var path := PlayerData.get_slot_path(slot_index)
	if not FileAccess.file_exists(path) and slot_index == 1:
		path = PlayerData.SAVE_PATH

	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}


func _on_slot_selected(slot_index: int) -> void:
	if PlayerData.load_game(slot_index):
		if AudioManager:
			AudioManager.stop_music()
		get_tree().change_scene_to_file(game_scene)
