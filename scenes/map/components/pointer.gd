extends Control

@export var waypoint_group: StringName = &"waypoints"
@export var color: Color = Color(1.0, 0.85, 0.2)          # default color; a waypoint can override it (see below)
@export var outline_color: Color = Color(0, 0, 0, 0.8)
@export var arrow_size: float = 18.0
@export var edge_margin: float = 48.0       # how far from the screen edge the arrow sits
@export var onscreen_offset: float = 36.0   # how high above the target it floats
@export var bob_amount: float = 6.0
@export var show_distance: bool = false
@export var pixels_per_unit: float = 16.0   # world pixels per "m" in the distance label

var _entries: Array[Dictionary] = []   # each: {"id": String, "node": Node2D}
var _arrows: Array[Dictionary] = []    # rebuilt every frame for drawing
var _had_arrows: bool = false
var _time: float = 0.0


func _ready() -> void:
	add_to_group("waypoint_marker")


# --- Public API -------------------------------------------------------

# Replace all targets. Accepts one waypoint name or a list of names:
#   point_to("forge")   point_to(["forge", "gate"])   point_to("")  <- hides everything
func point_to(ids: Variant = "") -> void:
	_entries.clear()
	if ids is Array:
		for id in ids:
			add_waypoint(str(id))
	else:
		add_waypoint(str(ids))


# Add one more waypoint without touching the others.
func add_waypoint(id: String) -> void:
	if id == "":
		return
	for e in _entries:
		if e.id == id:
			return
	_entries.append({"id": id, "node": null})


# Remove just this one waypoint.
func remove_waypoint(id: String) -> void:
	for i in range(_entries.size() - 1, -1, -1):
		if _entries[i].id == id:
			_entries.remove_at(i)


# Point at any Node2D directly (replaces all targets).
func point_to_node(node: Node2D) -> void:
	_entries.clear()
	add_node(node)


# Add any Node2D as an extra target.
func add_node(node: Node2D) -> void:
	for e in _entries:
		if e.node == node:
			return
	_entries.append({"id": "", "node": node})


func clear() -> void:
	_entries.clear()


# --- Per-frame update -------------------------------------------------

func _process(delta: float) -> void:
	_time += delta
	_arrows.clear()

	if not _entries.is_empty():
		var canvas := get_viewport().get_canvas_transform()
		var screen_size := get_viewport_rect().size
		var inner := Rect2(Vector2.ONE * edge_margin, screen_size - Vector2.ONE * edge_margin * 2.0)

		for e in _entries:
			# Resolve lazily so maps that load later still work
			if not is_instance_valid(e.node) and e.id != "":
				e.node = _find_waypoint(e.id)
			if is_instance_valid(e.node):
				_arrows.append(_make_arrow(e.node, canvas, screen_size, inner))

	if not _arrows.is_empty() or _had_arrows:
		queue_redraw()
	_had_arrows = not _arrows.is_empty()


func _make_arrow(node: Node2D, canvas: Transform2D, screen_size: Vector2, inner: Rect2) -> Dictionary:
	var screen_pos: Vector2 = canvas * node.global_position
	var pos: Vector2
	var angle: float

	if inner.has_point(screen_pos):
		# On screen: bob above the target, pointing down
		pos = screen_pos + Vector2(0, -onscreen_offset + sin(_time * 4.0) * bob_amount)
		angle = PI / 2.0
	else:
		# Off screen: stick to the edge, point toward the target
		var center := screen_size / 2.0
		var dir := screen_pos - center
		var half := center - Vector2.ONE * edge_margin
		var s := minf(half.x / maxf(absf(dir.x), 0.001), half.y / maxf(absf(dir.y), 0.001))
		pos = center + dir * s
		angle = dir.angle()

	var distance := 0.0
	if show_distance:
		var view_center_world: Vector2 = canvas.affine_inverse() * (screen_size / 2.0)
		distance = view_center_world.distance_to(node.global_position)

	# A waypoint can set its own color through metadata "marker_color"
	var arrow_color := color
	if node.has_meta("marker_color"):
		var m = node.get_meta("marker_color")
		if m is Color:
			arrow_color = m

	return {"pos": pos, "angle": angle, "color": arrow_color, "distance": distance}


# --- Drawing ----------------------------------------------------------

func _draw() -> void:
	for a in _arrows:
		_draw_arrow(a)


func _draw_arrow(a: Dictionary) -> void:
	var pts := PackedVector2Array([
		Vector2(arrow_size, 0),
		Vector2(-arrow_size * 0.6, -arrow_size * 0.7),
		Vector2(-arrow_size * 0.6, arrow_size * 0.7),
	])
	for i in pts.size():
		pts[i] = pts[i].rotated(a.angle) + a.pos

	draw_colored_polygon(pts, a.color)
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, outline_color, 2.0)

	if show_distance:
		var text := "%d m" % roundi(a.distance / pixels_per_unit)
		draw_string(ThemeDB.fallback_font, a.pos + Vector2(-30, -arrow_size - 6),
				text, HORIZONTAL_ALIGNMENT_CENTER, 60, 16, a.color)


func _find_waypoint(id: String) -> Node2D:
	for node in get_tree().get_nodes_in_group(waypoint_group):
		if node.name == id and node is Node2D:
			return node as Node2D
	return null
