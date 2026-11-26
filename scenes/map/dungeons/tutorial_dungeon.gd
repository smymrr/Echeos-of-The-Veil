extends Node2D

const BGM := "res://assets/audio/music/dungeon_ambient.mp3"

func _ready() -> void:
	AudioManager.play_music(BGM)
