extends CharacterBody2D

@export var npc_name: String = "Eldric"
@export var quest: Quest

@onready var interact_area: Area2D = $InteractArea
@onready var prompt: Control = $PromptLabel

const START_QUEST := [
	{"who": "npc", "text": "Oh, hello."},
	{"who": "npc", "text": "I didn't expect anyone to wander this far into the woods."},
	{"who": "npc", "text": "My name is Eldric. I've been charting the old ruins just south of here."},
	{"who": "mc", "text": "I have come for the Veil fragment."},
	{"who": "npc", "text": "Then you're looking for what's inside that dungeon. I can lead you to the entrance, but I won't send you in unprepared—clear out the slimes along the dirt path to the east first. Think you can handle them?",
		"choices": [
			{"text": "I'll clear the path.", "goto": 5, "result": "accepted"},
			{"text": "Give me a moment to prepare.", "goto": 7, "result": "declined"},
		]},
	{"who": "npc", "text": "Good. Head east onto the dirt road and watch for when they puff up before lunging. Wipe them out, and I'll guide you down to the ruins."},
	{"who": "mc", "text": "Consider it done.", "end": true},
	{"who": "npc", "text": "No rush. Come back and speak to me once you're ready to head east.", "end": true},
]

const ONGOING_QUEST := [
	{"who": "npc", "text": "Watch out for when they puf up before lunging. Wipe them out, and I'll guide you down to the ruins.", "end": true}
]

const FINISHED_QUEST := [
	{"who": "npc", "text": "Great work! You have potential to be a great warrior."},
	{"who": "npc", "text": "Follow me, I'll lead you to the dungeon.", "end": true}
]

var player_in_range: bool = false

var can_interact: bool = true
enum state {START, ONGOING, FINISHED}
var current_state = state.START
var current_line = START_QUEST

var _accepted := false
var _in_conversation := false   # true only for the conversation this NPC started

var player: CharacterBody2D

func _ready() -> void:
	prompt.hide()
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	
	ConversationManager.choice_result.connect(_on_choice_result)
	ConversationManager.conversation_ended.connect(on_conversation_ended)
	QuestManager.quest_completed.connect(on_quest_finished)

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

	if ConversationManager.is_talking():
		ConversationManager.advance()
	else:
		interact()

func interact() -> void:
	if not can_interact:
		return

	player.set_movement_lock(true, true)
	player.set_attack_enable(false)
	_accepted = false
	_in_conversation = true
	ConversationManager.start(current_line, "ELDRIC")

	can_interact = false


func _on_choice_result(result: String) -> void:
	if not _in_conversation:
		return
	_accepted = (result == "accepted")

func on_conversation_ended() -> void:
	if not _in_conversation:
		return
	_in_conversation = false

	if current_state == state.START and _accepted:
		current_state = state.ONGOING
		current_line = ONGOING_QUEST
		if quest:
			QuestManager.start_quest(quest)
	# declined: stays in START, so Eldric offers the quest again

	player.set_movement_lock(false)
	player.set_attack_enable(true)
	can_interact = true

func on_quest_finished(completed_quest: Quest) -> void:
	print("finished quest")
	if completed_quest == quest:
		print("quest completed!")
		current_state = state.FINISHED
		current_line = FINISHED_QUEST
