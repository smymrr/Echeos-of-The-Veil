extends Area2D

signal opened(chest)

@export var loot_id: String = ""   # whatever you use to identify the loot

var is_open := false
var player_in_range := false

@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var prompt: Label = get_node_or_null("Label")

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if prompt:
		prompt.hide()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		if prompt and not is_open:
			prompt.show()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		if prompt:
			prompt.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and player_in_range and not is_open:
		open()
		get_viewport().set_input_as_handled()

func open() -> void:
	is_open = true
	
	sprite.frame = 1
	
	if prompt:
		prompt.hide()
	opened.emit(self)
	# give loot here, e.g. PlayerData.add_item(loot_id)
