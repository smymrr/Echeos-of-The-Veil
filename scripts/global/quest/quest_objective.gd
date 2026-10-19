class_name QuestObjective
extends Resource

@export var type: String = "kill"      # "kill", "collect", "talk"...
@export var target_id: String = ""     # "slime", "apple", "old_man"
@export var required: int = 1
@export var description: String = ""
