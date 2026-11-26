extends Node2D

## Dikirim sekali saja, saat semua slime di stage ini sudah mati.
signal stage_cleared

const SLIME = preload("res://scenes/character/enemy/slime.tscn")

@export var unlock_barrier_id: String = "stage_1_barrier"   # barrier yang dibuka saat stage selesai ("" = tidak ada)
@export var tutorial_event: String = ""      # event untuk tutorial saat stage selesai ("" = tidak ada)

var _slimes: Array = []
var _cleared := false

func _ready() -> void:
	for spawn in get_children():
		if not spawn is Marker2D:
			continue
		var slime = SLIME.instantiate()
		slime.level = randi_range(1, 5)
		add_child(slime)
		slime.global_position = spawn.global_position   # setelah add_child, supaya posisi dunia benar
		_slimes.append(slime)

func _process(_delta: float) -> void:
	if _cleared or _slimes.is_empty():
		return
	# Buang slime yang sudah dihapus atau sedang dihapus
	_slimes = _slimes.filter(func(s): return is_instance_valid(s) and not s.is_queued_for_deletion())
	if _slimes.is_empty():
		_on_cleared()

func _on_cleared() -> void:
	_cleared = true
	stage_cleared.emit()
	if unlock_barrier_id != "":
		get_tree().call_group("tutorial_barrier", "unlock", unlock_barrier_id)
	if tutorial_event != "":
		get_tree().call_group("tutorial", "notify", tutorial_event)
