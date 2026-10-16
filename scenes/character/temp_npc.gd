extends CharacterBody2D

@export var npc_name: String = "Eldric"
@export var quest: Quest

@onready var interact_area: Area2D = $InteractArea
@onready var prompt: Control = $PromptLabel

var player_in_range: bool = false

func _ready() -> void:
	prompt.hide()
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.name == "Player":
		player_in_range = true
		prompt.show()

func _on_body_exited(body: Node) -> void:
	if body.name == "Player":
		player_in_range = false
		prompt.hide()

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed("interact"):
		interact()
		get_viewport().set_input_as_handled()

func interact() -> void:
	print("Talking to ", npc_name)
	QuestManager.start_quest(quest)
	
	if quest:
		QuestManager.start_quest(quest)
		QuestManager.report("talk", "old_man")   # for "talk to X" objectives
