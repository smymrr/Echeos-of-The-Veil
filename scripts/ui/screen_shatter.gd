class_name ScreenShatter
extends CanvasLayer

signal cracked
signal shattered_to_black
signal continue_requested

@export_group("Crack Tuning")
## Number of crack bursts (and crack SFX plays) before the screen shatters.
@export_range(0, 10, 1) var crack_count: int = 4
## How much of the screen spiderwebs with cracks before breaking (0.2 = localized, 1.0 = full screen).
@export_range(0.1, 1.0, 0.05) var crack_coverage: float = 0.7
## Seconds between each crack burst.
@export var crack_interval: float = 0.5
## Pause after the final crack before the screen shatters to black.
@export var hold_before_shatter: float = 0.45

@export_group("Shatter Physics")
@export var grid_columns: int = 12
@export var grid_rows: int = 8
@export var shatter_duration: float = 1.15
@export var gravity: float = 1900.0
@export var burst_speed: float = 280.0

@export_group("Audio")
## Optional direct AudioStreams (takes priority over the path strings below if assigned).
@export var crack_sfx: AudioStream
@export var shatter_sfx: AudioStream
## AudioManager paths relative to base_audio_dir ("res://assets/audio/").
@export var crack_sfx_path: String = "sfx/screen_shatter/screen_crack.wav"
@export var shatter_sfx_path: String = "sfx/screen_shatter/screen_shatter.wav"
@export_range(0.0, 0.5, 0.01) var crack_pitch_variance: float = 0.12
@export_range(0.0, 0.5, 0.01) var shatter_pitch_variance: float = 0.05

var _black_bg: ColorRect
var _shard_container: Node2D
var _crack_container: Node2D
var _shards: Array[Dictionary] = []
var _shattering := false
var _waiting_for_continue := false


func _ready() -> void:
	layer = 110  # Above game UI; LoadingScreen can still draw over it if needed


func play(impact_screen_pos: Vector2) -> void:
	# Wait for the current frame to finish rendering, then capture the screen
	await RenderingServer.frame_post_draw

	var vp := get_viewport()
	var vp_size := vp.get_visible_rect().size
	var img := vp.get_texture().get_image()
	if img.get_size() != Vector2i(vp_size):
		img.resize(int(vp_size.x), int(vp_size.y), Image.INTERPOLATE_BILINEAR)
	var screen_tex := ImageTexture.create_from_image(img)

	# 1. Pure black backdrop revealed as shards crack and fall away
	_black_bg = ColorRect.new()
	_black_bg.color = Color.BLACK
	_black_bg.size = vp_size
	add_child(_black_bg)

	_shard_container = Node2D.new()
	add_child(_shard_container)

	_crack_container = Node2D.new()
	add_child(_crack_container)

	# 2. Generate jittered points + impact origin and triangulate into shards
	var origin := impact_screen_pos.clamp(Vector2(40, 40), vp_size - Vector2(40, 40))
	var points := _generate_fracture_points(vp_size, origin)
	var indices := Geometry2D.triangulate_delaunay(points)
	var edges := _build_shards_and_edges(points, indices, screen_tex, origin)

	# 3. Animate cracks spreading outward in bursts
	await _animate_cracks(edges)
	cracked.emit()

	if hold_before_shatter > 0.0:
		await get_tree().create_timer(hold_before_shatter).timeout

	# 4. Break shards apart into black
	_play_sfx(shatter_sfx, shatter_sfx_path, shatter_pitch_variance)
	_crack_container.visible = false
	_shattering = true

	await get_tree().create_timer(shatter_duration).timeout
	_shattering = false
	shattered_to_black.emit()


func _process(delta: float) -> void:
	if not _shattering:
		return

	for shard in _shards:
		var poly: Polygon2D = shard["node"]
		var vel: Vector2 = shard["vel"]
		vel.y += gravity * delta
		shard["vel"] = vel
		poly.position += vel * delta
		poly.rotation += shard["rot_speed"] * delta


func _generate_fracture_points(vp_size: Vector2, origin: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var cell_w := vp_size.x / float(grid_columns)
	var cell_h := vp_size.y / float(grid_rows)

	for y in range(grid_rows + 1):
		for x in range(grid_columns + 1):
			var px := x * cell_w
			var py := y * cell_h
			if x > 0 and x < grid_columns:
				px += randf_range(-cell_w * 0.35, cell_w * 0.35)
			if y > 0 and y < grid_rows:
				py += randf_range(-cell_h * 0.35, cell_h * 0.35)
			pts.append(Vector2(px, py))

	pts.append(origin)
	return pts


func _build_shards_and_edges(
	points: PackedVector2Array,
	indices: PackedInt32Array,
	screen_tex: Texture2D,
	origin: Vector2
) -> Array[Array]:
	var edge_map: Dictionary = {}

	for i in range(0, indices.size(), 3):
		var p0 := points[indices[i]]
		var p1 := points[indices[i + 1]]
		var p2 := points[indices[i + 2]]
		var center := (p0 + p1 + p2) / 3.0

		var poly := Polygon2D.new()
		poly.texture = screen_tex
		poly.polygon = PackedVector2Array([p0 - center, p1 - center, p2 - center])
		poly.uv = PackedVector2Array([p0, p1, p2])
		poly.position = center
		_shard_container.add_child(poly)

		var out_dir := (center - origin).normalized()
		if out_dir == Vector2.ZERO:
			out_dir = Vector2.UP
		var speed := randf_range(burst_speed * 0.4, burst_speed * 1.2)
		var vel := out_dir * speed + Vector2(randf_range(-80.0, 80.0), randf_range(-160.0, -30.0))

		_shards.append({
			"node": poly,
			"vel": vel,
			"rot_speed": randf_range(-4.5, 4.5)
		})

		for pair in [[indices[i], indices[i + 1]], [indices[i + 1], indices[i + 2]], [indices[i + 2], indices[i]]]:
			var a: int = mini(pair[0], pair[1])
			var b: int = maxi(pair[0], pair[1])
			var key := "%d_%d" % [a, b]
			if not edge_map.has(key):
				var pa := points[a]
				var pb := points[b]
				edge_map[key] = [pa, pb, minf(pa.distance_to(origin), pb.distance_to(origin))]

	var edges: Array[Array] = []
	for item in edge_map.values():
		edges.append(item)
	edges.sort_custom(func(a: Array, b: Array) -> bool: return a[2] < b[2])
	return edges


func _animate_cracks(edges: Array[Array]) -> void:
	if edges.is_empty() or crack_count <= 0:
		return

	var max_edges := maxi(1, int(round(edges.size() * clampf(crack_coverage, 0.05, 1.0))))
	var visible_edges := edges.slice(0, max_edges)
	var chunk_size := maxi(1, ceili(float(visible_edges.size()) / float(crack_count)))

	for wave in range(crack_count):
		var start_idx := wave * chunk_size
		if start_idx >= visible_edges.size():
			break
		var end_idx := mini(visible_edges.size(), start_idx + chunk_size)

		for i in range(start_idx, end_idx):
			var pa: Vector2 = visible_edges[i][0]
			var pb: Vector2 = visible_edges[i][1]

			var dark_line := Line2D.new()
			dark_line.points = PackedVector2Array([pa, pb])
			dark_line.width = 3.2
			dark_line.default_color = Color(0.03, 0.03, 0.05, 0.95)
			_crack_container.add_child(dark_line)

			var glint_line := Line2D.new()
			glint_line.points = PackedVector2Array([pa, pb])
			glint_line.width = 1.1
			glint_line.default_color = Color(0.85, 0.95, 1.0, 0.75)
			_crack_container.add_child(glint_line)

		_play_sfx(crack_sfx, crack_sfx_path, crack_pitch_variance)
		_micro_shake(maxf(1.5, 6.0 - wave * 1.2))
		await get_tree().create_timer(crack_interval).timeout


func _micro_shake(strength: float) -> void:
	if not is_instance_valid(_shard_container):
		return
	var tween := create_tween()
	tween.tween_property(_shard_container, "position", Vector2(strength, -strength * 0.6), 0.04)
	tween.tween_property(_shard_container, "position", Vector2(-strength * 0.7, strength * 0.5), 0.04)
	tween.tween_property(_shard_container, "position", Vector2.ZERO, 0.04)


func _play_sfx(stream: AudioStream, rel_path: String, pitch_var: float) -> void:
	if stream != null:
		AudioManager.play_stream(stream, pitch_var)
		return
	if rel_path == "":
		return
	var base := rel_path if rel_path.begins_with("res://") else AudioManager.base_audio_dir.path_join(rel_path)
	if ResourceLoader.exists(base) or ResourceLoader.exists(base + ".wav") or ResourceLoader.exists(base + ".mp3") or ResourceLoader.exists(base + ".ogg"):
		AudioManager.play(rel_path, pitch_var)


func _input(event: InputEvent) -> void:
	if not _waiting_for_continue:
		return
	if (event is InputEventKey or event is InputEventMouseButton) and event.pressed and not event.is_echo():
		_waiting_for_continue = false
		continue_requested.emit()


func show_to_be_continued(
	title_text: String = "To Be Continued...",
	prompt_text: String = "Press any key to return to title",
	wait_for_input: bool = true
) -> void:
	var vp_size := get_viewport().get_visible_rect().size

	if not is_instance_valid(_black_bg):
		_black_bg = ColorRect.new()
		_black_bg.color = Color.BLACK
		_black_bg.size = vp_size
		add_child(_black_bg)

	var container := VBoxContainer.new()
	container.size = vp_size
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 18)
	add_child(container)

	var title_label := Label.new()
	title_label.text = title_text
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 42)
	title_label.modulate.a = 0.0
	container.add_child(title_label)

	var prompt_label := Label.new()
	prompt_label.text = prompt_text
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 16)
	prompt_label.modulate = Color(0.75, 0.75, 0.75, 0.0)
	container.add_child(prompt_label)

	# Fade in "To Be Continued..." with a subtle upward drift
	var start_y := title_label.position.y
	title_label.position.y = start_y + 12.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(title_label, "modulate:a", 1.0, 1.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(title_label, "position:y", start_y, 1.4) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

	await get_tree().create_timer(1.2).timeout

	if wait_for_input and prompt_text != "":
		var prompt_tween := create_tween()
		prompt_tween.tween_property(prompt_label, "modulate:a", 0.85, 0.8)
		await prompt_tween.finished

		_waiting_for_continue = true
		await continue_requested

		var fade_out := create_tween()
		fade_out.tween_property(container, "modulate:a", 0.0, 0.6)
		await fade_out.finished
