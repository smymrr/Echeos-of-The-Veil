extends BaseButton

@export var hover_audio_path: NodePath = ^"../MenuPanel/HoverAudio"
@export var click_audio_path: NodePath = ^"../MenuPanel/ClickAudio"

@export var hover_scale: float = 1.08
@export var hover_color: Color = Color(1.25, 1.25, 1.4)
@export var tween_duration: float = 0.12

var _hover_audio: AudioStreamPlayer
var _click_audio: AudioStreamPlayer
var _original_scale: Vector2
var _original_modulate: Color
var _tween: Tween


func _ready() -> void:
	pivot_offset = size / 2.0
	_original_scale = scale
	_original_modulate = modulate

	_hover_audio = get_node_or_null(hover_audio_path)
	_click_audio = get_node_or_null(click_audio_path)

	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)
	pressed.connect(_on_pressed)
	focus_entered.connect(_on_hover)
	focus_exited.connect(_on_unhover)


func _on_hover() -> void:
	if _hover_audio:
		_hover_audio.play()
	_animate(_original_scale * hover_scale, hover_color)


func _on_unhover() -> void:
	_animate(_original_scale, _original_modulate)


func _on_pressed() -> void:
	if _click_audio:
		_click_audio.play()

	var punch := create_tween()
	punch.tween_property(self, "scale", _original_scale * 0.92, 0.05)
	punch.tween_property(self, "scale", _original_scale * hover_scale, 0.08)


func _animate(target_scale: Vector2, target_color: Color) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_OUT)

	_tween.tween_property(self, "scale", target_scale, tween_duration)
	_tween.tween_property(self, "modulate", target_color, tween_duration)
