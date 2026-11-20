extends Control

@export var waypoint_group: StringName = &"waypoints"
@export var color: Color = Color(1.0, 0.85, 0.2)
@export var outline_color: Color = Color(0, 0, 0, 0.8)
@export var arrow_size: float = 18.0
@export var edge_margin: float = 48.0       # how far from the screen edge the arrow sits
@export var onscreen_offset: float = 36.0   # how high above the target it floats
@export var bob_amount: float = 6.0
@export var show_distance: bool = false
@export var pixels_per_unit: float = 16.0   # world pixels per "m" in the distance label

var _target: Node2D
var _target_id: String = ""
var _time: float = 0.0
var _show: bool = false
var _draw_pos: Vector2
var _angle: float = 0.0
var _distance: float = 0.0


func _ready() -> void:
	add_to_group("waypoint_marker")


# Point at the waypoint with this node name. "" hides the marker.
func point_to(id: String) -> void:
	_target_id = id
	_target = null
	if id == "":
		_show = false
		queue_redraw()


# Point at any Node2D directly.
func point_to_node(node: Node2D) -> void:
	_target_id = ""
	_target = node


func clear() -> void:
	point_to("")


func _process(delta: float) -> void:
	_time += delta

	# Resolve lazily so maps that load later still work
	if not is_instance_valid(_target) and _target_id != "":
		_target = _find_waypoint(_target_id)

	if not is_instance_valid(_target):
		if _show:
			_show = false
			queue_redraw()
		return

	var canvas := get_viewport().get_canvas_transform()
	var screen_size := get_viewport_rect().size
	var screen_pos: Vector2 = canvas * _target.global_position
	var inner := Rect2(Vector2.ONE * edge_margin, screen_size - Vector2.ONE * edge_margin * 2.0)

	if inner.has_point(screen_pos):
		# On screen: bob above the target, pointing down
		_draw_pos = screen_pos + Vector2(0, -onscreen_offset + sin(_time * 4.0) * bob_amount)
		_angle = PI / 2.0
	else:
		# Off screen: stick to the edge, point toward the target
		var center := screen_size / 2.0
		var dir := screen_pos - center
		var half := center - Vector2.ONE * edge_margin
		var s := minf(half.x / maxf(absf(dir.x), 0.001), half.y / maxf(absf(dir.y), 0.001))
		_draw_pos = center + dir * s
		_angle = dir.angle()

	if show_distance:
		var view_center_world: Vector2 = canvas.affine_inverse() * (screen_size / 2.0)
		_distance = view_center_world.distance_to(_target.global_position)

	_show = true
	queue_redraw()


func _draw() -> void:
	if not _show:
		return

	var pts := PackedVector2Array([
		Vector2(arrow_size, 0),
		Vector2(-arrow_size * 0.6, -arrow_size * 0.7),
		Vector2(-arrow_size * 0.6, arrow_size * 0.7),
	])
	for i in pts.size():
		pts[i] = pts[i].rotated(_angle) + _draw_pos

	draw_colored_polygon(pts, color)
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, outline_color, 2.0)

	if show_distance:
		var text := "%d m" % roundi(_distance / pixels_per_unit)
		draw_string(ThemeDB.fallback_font, _draw_pos + Vector2(-30, -arrow_size - 6),
				text, HORIZONTAL_ALIGNMENT_CENTER, 60, 16, color)


func _find_waypoint(id: String) -> Node2D:
	for node in get_tree().get_nodes_in_group(waypoint_group):
		if node.name == id and node is Node2D:
			return node as Node2D
	return null
