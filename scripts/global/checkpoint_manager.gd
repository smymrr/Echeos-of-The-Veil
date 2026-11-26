extends Node
## Mengingat checkpoint terakhir dan memindahkan player ke sana setelah respawn.

signal checkpoint_set(id: String)

var _scene_path: String = ""
var _position: Vector2 = Vector2.ZERO
var _id: String = ""
var _map_id: String = ""
var _respawn_pending := false

func has_checkpoint() -> bool:
	return _scene_path != ""

func set_checkpoint(scene_path: String, pos: Vector2, id: String = "", map_id: String = "") -> void:
	_scene_path = scene_path
	_position = pos
	_id = id
	_map_id = map_id if map_id != "" else PlayerData.current_map
	checkpoint_set.emit(id)
	print("checkpoint success! ", _position)

func clear() -> void:
	_scene_path = ""
	_position = Vector2.ZERO
	_id = ""
	_map_id = ""
	_respawn_pending = false

func is_respawning() -> bool:
	return _respawn_pending

func get_checkpoint_map() -> String:
	return _map_id
	
## Dipanggil tombol RETRY. Tanpa checkpoint: muat ulang scene seperti biasa.
func respawn() -> void:
	get_tree().paused = false
	
	if not has_checkpoint():
		get_tree().reload_current_scene()
		return
	_respawn_pending = true
	PlayerHealth.heal(PlayerData.get_max_health())
	PlayerHealth.is_dead = false
	get_tree().call_group("player", "set_movement_lock", false)
	
	get_tree().change_scene_to_file(_scene_path)   # scene yang sama = reload

## Dipanggil player di _ready(): pindahkan ke checkpoint kalau sedang respawn.
func apply_respawn(player: Node2D) -> void:
	if not _respawn_pending:
		return
	_respawn_pending = false
	player.global_position = _position
	print("respawned")
	# Supaya kamera tidak "meluncur" dari posisi lama
	for child in player.get_children():
		if child is Camera2D:
			child.reset_smoothing()
