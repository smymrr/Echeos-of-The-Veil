class_name FootstepComponent
extends Node

@export_group("Surface Audio")
## Default surface used when no terrain data is found under the player.
@export var default_surface: String = "grass"
## Drag your grass footstep .wav files here.
@export var grass_streams: Array[AudioStream] = []
## Drag your stone footstep .wav files here.
@export var stone_streams: Array[AudioStream] = []
## Optional extra surfaces: { "wood": [stream1, stream2], "water": [stream1] }
@export var extra_surface_streams: Dictionary = {}
## Fallback folder path if stream arrays are empty (plays "<path>_<surface>", e.g. "sfx/player/footstep_grass").
@export var fallback_sound_prefix: String = "sfx/player/footstep"
@export_range(0.0, 0.5, 0.01) var pitch_variance: float = 0.12

@export_group("Terrain Detection")
## Custom Data Layer name on your TileSet (String type: "grass", "stone", etc.).
@export var custom_data_layer: String = "surface"
## Offset from Player's origin to their feet so tiles are sampled at boot level.
@export var foot_offset: Vector2 = Vector2(0, 8)
## Optional Marker2D at the player's feet (overrides foot_offset if assigned).
@export var foot_marker: Node2D

@export_group("Timer Mode")
@export var step_interval: float = 0.35
@export var min_move_speed: float = 20.0

@export_group("Animation Frame Sync (Optional)")
@export var sync_to_frames: bool = false
@export var sprite: AnimatedSprite2D
@export var walk_animation_prefix: String = "walk"
@export var step_frames: Array[int] = [1, 3]

const INITIAL_STEP_DELAY := 0.08

var _body: CharacterBody2D
var _step_timer: float = INITIAL_STEP_DELAY
var _last_stream_indices: Dictionary = {}


func _ready() -> void:
	_body = get_parent() as CharacterBody2D
	if _body == null:
		push_warning("FootstepComponent: Parent must be a CharacterBody2D.")
		set_physics_process(false)
		return

	if sync_to_frames and sprite != null:
		sprite.frame_changed.connect(_on_sprite_frame_changed)


func _physics_process(delta: float) -> void:
	if sync_to_frames and sprite != null:
		return

	if not _is_walking():
		_step_timer = INITIAL_STEP_DELAY
		return

	_step_timer -= delta
	if _step_timer <= 0.0:
		play_footstep()
		_step_timer = step_interval


func _on_sprite_frame_changed() -> void:
	if not _is_walking():
		return

	var anim_name := String(sprite.animation).to_lower()
	if not anim_name.begins_with(walk_animation_prefix.to_lower()):
		return

	if sprite.frame in step_frames:
		play_footstep()


func _is_walking() -> bool:
	if PlayerHealth.is_dead:
		return false

	var mc = _body.get("movement_component")
	if mc != null:
		if mc.get("is_dashing") or mc.get("is_locked"):
			return false

	return _body.velocity.length() >= min_move_speed


func get_foot_position() -> Vector2:
	if is_instance_valid(foot_marker):
		return foot_marker.global_position
	return _body.global_position + foot_offset


func get_current_surface() -> String:
	var check_pos := get_foot_position()

	# 1. Check Area2D overrides first (useful for stone bridges over grass, carpets, etc.)
	var area_surface := _get_area_surface(check_pos)
	if area_surface != "":
		return area_surface

	# 2. Check TileMapLayers from highest z_index / draw order downwards
	var tile_surface := _get_tilemap_surface(check_pos)
	if tile_surface != "":
		return tile_surface

	return default_surface.to_lower()


func _get_area_surface(check_pos: Vector2) -> String:
	var space := _body.get_world_2d().direct_space_state
	var query := PhysicsPointQueryParameters2D.new()
	query.position = check_pos
	query.collide_with_areas = true
	query.collide_with_bodies = false

	for hit in space.intersect_point(query):
		var area: Area2D = hit.collider as Area2D
		if area == null:
			continue
		if area.has_meta("surface"):
			return str(area.get_meta("surface")).to_lower()
		for group in area.get_groups():
			var group_name := String(group).to_lower()
			if group_name.begins_with("surface_"):
				return group_name.trim_prefix("surface_")

	return ""


func _get_tilemap_surface(check_pos: Vector2) -> String:
	var layers := _collect_tilemap_layers(get_tree().current_scene)
	# Reverse so layers drawn on top (e.g., stone path over grass) are checked first
	layers.reverse()
	layers.sort_custom(func(a: TileMapLayer, b: TileMapLayer) -> bool:
		return a.z_index > b.z_index
	)

	for layer in layers:
		if not layer.visible or layer.tile_set == null:
			continue
		if layer.tile_set.get_custom_data_layer_by_name(custom_data_layer) == -1:
			continue

		var cell := layer.local_to_map(layer.to_local(check_pos))
		var tile_data := layer.get_cell_tile_data(cell)
		if tile_data == null:
			continue

		var surface = tile_data.get_custom_data(custom_data_layer)
		if surface is String and surface != "":
			return surface.to_lower()

	return ""


func _collect_tilemap_layers(root: Node) -> Array[TileMapLayer]:
	var result: Array[TileMapLayer] = []
	if root == null:
		return result
	for child in root.get_children():
		if child is TileMapLayer:
			result.append(child)
		if child.get_child_count() > 0:
			result.append_array(_collect_tilemap_layers(child))
	return result


func play_footstep() -> void:
	var surface := get_current_surface()
	var streams := _get_streams_for_surface(surface)

	if streams.size() > 0:
		var stream := _pick_stream(surface, streams)
		if stream:
			AudioManager.play_stream(stream, pitch_variance)
	elif fallback_sound_prefix != "":
		AudioManager.play("%s_%s" % [fallback_sound_prefix, surface], pitch_variance)


func _get_streams_for_surface(surface: String) -> Array[AudioStream]:
	match surface:
		"grass":
			return grass_streams
		"stone":
			return stone_streams
		_:
			if extra_surface_streams.has(surface):
				var typed: Array[AudioStream] = []
				for item in extra_surface_streams[surface]:
					if item is AudioStream:
						typed.append(item)
				return typed
	return grass_streams


func _pick_stream(surface: String, streams: Array[AudioStream]) -> AudioStream:
	if streams.size() == 1:
		return streams[0]

	var last_idx: int = _last_stream_indices.get(surface, -1)
	var idx := randi() % streams.size()
	if idx == last_idx:
		idx = (idx + 1) % streams.size()
	_last_stream_indices[surface] = idx
	return streams[idx]
