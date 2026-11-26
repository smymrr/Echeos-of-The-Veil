extends Area2D

@export var quest: Quest

@onready var prompt: Control = $PromptLabel

var player_in_range: bool = false
var can_interact: bool = true
var player: CharacterBody2D

func _ready() -> void:
	prompt.hide()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player = body
		player_in_range = true
		prompt.show()

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		prompt.hide()

func _unhandled_input(event: InputEvent) -> void:
	if not (player_in_range and event.is_action_pressed("interact")):
		return
	get_viewport().set_input_as_handled()
	interact()

func interact() -> void:
	if not can_interact:
		return
	
	can_interact = false
