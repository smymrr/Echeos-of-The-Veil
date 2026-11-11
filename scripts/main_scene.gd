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

# 1. Preload the scenes at the top of the file so they load into memory once
const LEVEL_1 = preload("res://scenes/map/tutorial/stage.tscn")
const PLAYER = preload("res://scenes/character/player.tscn")
const UI = preload("res://scenes/ui/game_ui.tscn")
const SLIME = preload("res://scenes/character/slime.tscn")

func start_game():

	var level_instance = LEVEL_1.instantiate()
	var player_instance = PLAYER.instantiate()
	var ui_instance = UI.instantiate()
	
	
	# 3. Get the root node of the currently active scene
	var game_root = get_tree().current_scene
	
	# 4. Add the instantiated nodes to the tree
	game_root.add_child(level_instance)
	game_root.add_child(ui_instance)
	
	# You can nest them dynamically too (putting the player inside the level)
	level_instance.add_child(player_instance)
	
	var spawn_point = level_instance.get_node("SpawnMarker2D") # or Marker2D
	if spawn_point:
		player_instance.global_position = spawn_point.global_position
	
	for child in level_instance.get_children():
		if "SlimeSpawn" in child.name:
			var slime_instance = SLIME.instantiate()
			game_root.add_child(slime_instance)
			slime_instance.global_position = child.global_position

func _ready() -> void:
	start_game()
