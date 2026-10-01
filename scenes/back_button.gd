extends Button

var hover_sound_player: AudioStreamPlayer
var click_sound_player: AudioStreamPlayer

func _ready() -> void:
	hover_sound_player = AudioStreamPlayer.new()
	hover_sound_player.stream = preload("res://assets/audio/main_menu/hover_sound.wav")
	add_child(hover_sound_player)

	click_sound_player = AudioStreamPlayer.new()
	click_sound_player.stream = preload("res://assets/audio/main_menu/back_click.wav")
	add_child(click_sound_player)

	mouse_entered.connect(_on_mouse_entered)
	pressed.connect(_on_pressed)

func _on_mouse_entered() -> void:
	hover_sound_player.play()

func _on_pressed() -> void:
	click_sound_player.play()
