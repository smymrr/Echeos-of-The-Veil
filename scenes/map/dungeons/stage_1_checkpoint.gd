class_name Checkpoint
extends Area2D

@export var checkpoint_id: String = ""
@export var respawn_point: Marker2D         # opsional: tempat player muncul. Kosong = posisi checkpoint ini
@export var player_group: StringName = "player"

var _used := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	print("entered")
	if _used or not body.is_in_group(player_group):
		return
	_used = true

	var pos := respawn_point.global_position if respawn_point else global_position
	CheckpointManager.set_checkpoint(get_tree().current_scene.scene_file_path, pos, checkpoint_id)

	# Umpan balik singkat: berkedip terang
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.6, 1.6, 1.0), 0.15)
	tween.tween_property(self, "modulate", Color.WHITE, 0.4)
