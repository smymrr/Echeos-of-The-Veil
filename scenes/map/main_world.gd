extends Node2D

const BGM := "res://assets/audio/music/overworld.mp3"

func _ready() -> void:
	AudioManager.play_music(BGM)
