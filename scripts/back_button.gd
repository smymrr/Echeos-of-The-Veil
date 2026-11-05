extends Button



func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	pressed.connect(_on_pressed)

func _on_mouse_entered() -> void:
	AudioManager.play("sfx/hover_sound.wav")

func _on_pressed() -> void:
	AudioManager.play("sfx/back_click.wav")
