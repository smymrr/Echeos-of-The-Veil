extends Node2D

# Assign slime.tscn in the Inspector (or change the path in the preload below)
@export var slime_scene: PackedScene

func _ready() -> void:
	if slime_scene == null:
		push_error("slime_scene is not assigned on %s" % name)
		return

	for child in get_children():
		if child is Node2D and child.name.contains("SlimeSpawner"):
			spawn_slime(child.global_position)


func spawn_slime(spawn_position: Vector2) -> Node2D:
	var slime := slime_scene.instantiate() as Node2D
	add_child(slime)
	slime.global_position = spawn_position
	return slime
