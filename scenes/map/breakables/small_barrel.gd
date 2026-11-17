extends StaticBody2D

var SFX = preload("res://assets/audio/sfx/crate_break.wav")

func break_object() -> void:
	AudioManager.play_stream(SFX)
	
	queue_free()
