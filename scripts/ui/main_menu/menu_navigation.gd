extends CanvasItem

@export_group("Tombol Menu")
@export var new_journey_button: NodePath
@export var load_data_button: NodePath
@export var synopsis_button: NodePath
@export var options_button: NodePath
@export var exit_button: NodePath

@export_group("Screen / Panel Tujuan")
@export var new_journey_screen: NodePath
@export var load_data_screen: NodePath
@export var synopsis_screen: NodePath
@export var options_screen: NodePath

var _screens: Array[Control] = []


func _ready() -> void:
	var pairs := [
		[new_journey_button, new_journey_screen],
		[load_data_button, load_data_screen],
		[synopsis_button, synopsis_screen],
		[options_button, options_screen],
	]

	for pair in pairs:
		var btn: BaseButton = get_node_or_null(pair[0])
		var screen: Control = get_node_or_null(pair[1])

		if screen:
			screen.visible = false
			_screens.append(screen)
			_connect_back_button(screen)

		if btn and screen:
			btn.pressed.connect(_show_screen.bind(screen))
		elif btn == null and pair[0] != NodePath():
			push_warning("Tombol tidak ditemukan: %s" % pair[0])
		elif screen == null and pair[1] != NodePath():
			push_warning("Screen tidak ditemukan: %s" % pair[1])

	var exit_btn: BaseButton = get_node_or_null(exit_button)
	if exit_btn:
		exit_btn.pressed.connect(_on_exit_pressed)


func _show_screen(screen: Control) -> void:
	visible = false # sembunyikan MenuPanel
	for s in _screens:
		s.visible = (s == screen)


func show_menu() -> void:
	visible = true
	for s in _screens:
		s.visible = false


func _on_exit_pressed() -> void:
	get_tree().quit()


func _connect_back_button(screen: Control) -> void:
	var back_btn := _find_node_by_name(screen, "BackButton")
	if back_btn and back_btn is BaseButton:
		back_btn.pressed.connect(show_menu)


func _find_node_by_name(node: Node, target_name: String) -> Node:
	for child in node.get_children():
		if child.name == target_name:
			return child
		var found := _find_node_by_name(child, target_name)
		if found:
			return found
	return null
