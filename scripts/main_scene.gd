extends Node2D

# main.gd
const UI = preload("res://scenes/ui/game_ui.tscn")
const TUTORIAL_UI = preload("res://scenes/ui/tutorial.tscn")
const WAYPOINT_MARKER = preload("res://scenes/map/components/waypoint_marker.tscn")

var current_map: Node2D
var _is_changing_map: bool = false

func _ready() -> void:
	start_game()

func start_game() -> void:
	var ui_instance = UI.instantiate()
	var game_root = get_tree().current_scene
	if not PlayerData.tutorial_shown:
		add_child(TUTORIAL_UI.instantiate())
		PlayerData.tutorial_shown = true
	add_child(WAYPOINT_MARKER.instantiate())

	game_root.add_child(ui_instance)

	var starting_map := "tutorial_overworld"
	if CheckpointManager.is_respawning() and CheckpointManager.get_checkpoint_map() != "":
		starting_map = CheckpointManager.get_checkpoint_map()

	load_map(starting_map)


func load_map(target: Variant, spawn_name := "default", map_id := "") -> void:
	if is_instance_valid(current_map):
		current_map.queue_free()
		await current_map.tree_exited

	var scene: PackedScene
	if target is PackedScene:
		scene = target
	else:
		var path: String = MapRegistry.MAPS.get(target)
		scene = load(path)

	current_map = scene.instantiate()
	$MapContainer.add_child(current_map)

	if CheckpointManager.has_checkpoint():
		pass
	else:
		var spawn: Marker2D = current_map.get_node("SpawnPoints/" + spawn_name)
		$Player.global_position = spawn.global_position

	if map_id != "":
		PlayerData.current_map = map_id
	elif target is String:
		PlayerData.current_map = target


func change_map(map_target: String, spawn_name := "default") -> void:
	if _is_changing_map:
		return
	_is_changing_map = true

	var map_path: String = MapRegistry.MAPS.get(map_target)
	var loader := LoadingScreen.load_overlay(get_tree(), map_path)
	var packed: PackedScene = await loader.scene_loaded
	await load_map(packed, spawn_name, map_target)

	_is_changing_map = false
