extends CanvasLayer

func _ready() -> void:
	QuestManager.quest_started.connect(_on_quest_started)
	QuestManager.quest_updated.connect(_refresh)
	QuestManager.quest_completed.connect(_on_quest_completed)

func _on_quest_started() -> void:
	print("Started quest")

func _on_quest_completed() -> void:
	print("Quest Completed")

func _refresh() -> void:
	print("Refreshed")
