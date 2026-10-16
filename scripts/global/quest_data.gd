class_name QuestData
extends Resource

@export var id: String
@export var title: String
@export var description: String
@export var is_main_story: bool = false
@export var objectives: Dictionary = {}
# objectives shape: { "kill_slimes": 5, "talk_to_elder": 1 }
# key = objective id, value = target count needed to complete it
