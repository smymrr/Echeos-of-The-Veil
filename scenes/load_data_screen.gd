extends Control  # sesuaikan tipe node LoadDataScreen kamu (Control/Panel/Node2D)

@export var fade_duration: float = 0.25

func _ready() -> void:
	# Pastikan panel siap untuk fade, mulai dari transparan & tersembunyi
	modulate.a = 0.0
	visible = false

func show_panel() -> void:
	visible = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_duration)

func hide_panel() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	await tween.finished
	visible = false
