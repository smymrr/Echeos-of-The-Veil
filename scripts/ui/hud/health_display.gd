extends HBoxContainer

@onready var Health: Label = get_node("HpValue")
@onready var HpBar: ProgressBar = get_node("HpBar")

func _ready() -> void:
	Health.text = str(PlayerHealth.get_health()) + "/" + str(PlayerData.get_max_health())
	HpBar.max_value = PlayerData.get_max_health()
	HpBar.value = PlayerHealth.get_health()
	
	PlayerHealth.health_changed.connect(_update_health_bar)

func _update_health_bar(new_health: int, max_health: int):
	Health.text = str(new_health) + "/" + str(max_health)
	HpBar.max_value = max_health
	HpBar.value = new_health
