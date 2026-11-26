class_name RunnerBar
extends ProgressBar
## Bar progres dengan sprite yang berdiri di ujung isian bar.
## Dari luar cukup isi `value` (0..1). Sprite dan label persen diurus di sini.

@export var runner: Node2D
@export var percent_label: Label
@export var run_animation: StringName = &"walk_right"   # nama animasi di SpriteFrames
@export var sprite_y_offset: float = 0.0                 # naik (-) / turun (+) kalau kurang pas


func _ready() -> void:
	min_value = 0.0
	max_value = 1.0
	step = 0.0
	show_percentage = false
	value = 0.0

	if runner is AnimatedSprite2D:
		var anim := runner as AnimatedSprite2D
		if anim.sprite_frames and anim.sprite_frames.has_animation(run_animation):
			anim.play(run_animation)
		else:
			push_warning("Animasi '%s' tidak ada di SpriteFrames, cek run_animation." % run_animation)
			anim.play()


func _process(_delta: float) -> void:
	if percent_label:
		percent_label.text = "%d%%" % int(ratio * 100.0)
	if runner:
		runner.global_position = Vector2(
			global_position.x + size.x * ratio,
			global_position.y - _runner_half_height() + sprite_y_offset
		)


## Setengah tinggi sprite, supaya kakinya menempel di tepi atas bar.
func _runner_half_height() -> float:
	var tex: Texture2D = null
	if runner is AnimatedSprite2D:
		var anim := runner as AnimatedSprite2D
		if anim.sprite_frames:
			tex = anim.sprite_frames.get_frame_texture(anim.animation, anim.frame)
	elif runner is Sprite2D:
		tex = (runner as Sprite2D).texture
	if tex == null:
		return 0.0
	return tex.get_height() * absf(runner.scale.y) * 0.5
