extends Label

func _ready() -> void:
	_update()

func _update() -> void:
	text = "DMG: " + str(PlayerData.get_attack())

func _process(delta: float) -> void:
	_update()
