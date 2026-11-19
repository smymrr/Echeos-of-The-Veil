extends CharacterBody2D

@export var npc_name: String = "Eldric"
@export var quest: Quest

@onready var interact_area: Area2D = $InteractArea
@onready var prompt: Control = $PromptLabel

const LINES := [
	{"who": "npc", "text": "Oh, hello."},
	{"who": "npc", "text": "I didn't expect anyone to wander this far into the woods."},
	{"who": "npc", "text": "My name is Eldric. I've been charting the old ruins just south of here."},
	{"who": "mc", "text": "I have come for the Veil fragment."},
	{"who": "npc", "text": "Then you're looking for what's inside that dungeon. I can lead you to the entrance, but I won't send you in unprepared—clear out the slimes along the dirt path to the east first. Think you can handle them?",
		"choices": [
			{"text": "I'll clear the path.", "goto": 5},
			{"text": "Give me a moment to prepare.", "goto": 7},
		]},
	{"who": "npc", "text": "Good. Head east onto the dirt road and watch for when they puff up before lunging. Wipe them out, and I'll guide you down to the ruins."},
	{"who": "mc", "text": "Consider it done.", "end": true},
	{"who": "npc", "text": "No rush. Come back and speak to me once you're ready to head east.", "end": true},
]

var player_in_range: bool = false

func _ready() -> void:
	prompt.hide()
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
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
	
	if player_in_range and event.is_action_pressed("left_click"):
		if ConversationManager.is_talking():
			ConversationManager.advance()

func interact() -> void:
	ConversationManager.start(LINES, "ELDRIC")
	
	QuestManager.start_quest(quest)
	
	if quest:
		QuestManager.start_quest(quest)
		QuestManager.report("talk", "old_man")   # for "talk to X" objectives
