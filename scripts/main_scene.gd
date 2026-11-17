extends Node2D

# main.gd
var current_map: Node2D

func load_map(map_id: String, spawn_name := "default") -> void:
	if current_map:
		current_map.queue_free()
		await current_map.tree_exited

	var scene: PackedScene = load(MapRegistry.MAPS[map_id])
	current_map = scene.instantiate()
	$MapContainer.add_child(current_map)

	var spawn: Marker2D = current_map.get_node("SpawnPoints/" + spawn_name)
	$Player.global_position = spawn.global_position
	PlayerData.current_map = map_id

const UI = preload("res://scenes/ui/game_ui.tscn")

func start_game():
	var ui_instance = UI.instantiate()
	var game_root = get_tree().current_scene

	game_root.add_child(ui_instance)

func _ready() -> void:
	start_game()
