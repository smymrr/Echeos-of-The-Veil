class_name Quest
extends Resource

@export var id: String = "" # quest id (kill_slime, kill_vampire, etc.)
@export var title: String = "" # quest title
@export_multiline var description: String = ""

@export var objectives: Array[QuestObjective] = []
@export var reward_gold: int = 0
