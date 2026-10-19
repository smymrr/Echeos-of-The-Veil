class_name Quest
extends Resource

@export var id: String = ""
@export var title: String = ""
@export_multiline var description: String = ""

@export var objectives: Array[QuestObjective] = []
@export var reward_gold: int = 0
