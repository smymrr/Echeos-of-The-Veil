extends Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	text = "HP: " + str(PlayerHealth.get_health()) + " / " + str(PlayerData.get_max_health())

func _update(current: int, max: int) -> void:
	text = "HP: " + str(current) + " / " + str(max)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_update(PlayerHealth.get_health(), PlayerData.get_max_health())
