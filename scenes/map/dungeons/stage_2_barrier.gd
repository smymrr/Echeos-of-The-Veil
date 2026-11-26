extends StaticBody2D

@export var barrier_id: String = "stage_2_barrier"
@export var fade_time: float = 0.4

var _open := false

func _ready() -> void:
	add_to_group("tutorial_barrier")

func unlock(id: String) -> void:
	if id == barrier_id:
		open()

func unlock_all() -> void:
	open()

func open() -> void:
	if _open:
		return
	_open = true
	
	set_deferred("collision_layer", 0)   # stops blocking the player right away
	set_deferred("collision_mask", 0)
	
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_time)
	tween.tween_callback(hide)
