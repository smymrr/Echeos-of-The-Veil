extends CanvasLayer

@onready var fps_label: Label = $MarginContainer/display
@onready var margin_container: MarginContainer = $MarginContainer

const DEFAULT_MARGIN: int = 20
const STATS_WIDTH_OFFSET: int = 200

func _process(_delta: float) -> void:
	fps_label.text = "FPS: " + str(Engine.get_frames_per_second())

	var current_scene = get_tree().current_scene
	if current_scene and current_scene.has_node("GameUI"):
		margin_container.add_theme_constant_override("margin_left", DEFAULT_MARGIN + STATS_WIDTH_OFFSET)
	else:
		margin_container.add_theme_constant_override("margin_left", DEFAULT_MARGIN)
