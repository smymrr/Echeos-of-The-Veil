extends Area2D

func _ready() -> void:
	self.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		get_tree().call_group("tutorial", "notify", "enter_2nd")
