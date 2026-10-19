extends Control

@onready var quest_label: Label = $CanvasLayer/Quest
@onready var progress_label: Label = $CanvasLayer/Progress

func _ready() -> void:
	QuestManager.quest_started.connect(func(_q): _refresh())
	QuestManager.quest_updated.connect(func(_q): _refresh())
	QuestManager.quest_completed.connect(_on_quest_completed)
	_refresh()

func _refresh() -> void:
	# Nothing active: clear the HUD
	if QuestManager.active.is_empty():
		quest_label.text = ""
		progress_label.text = ""
		return

	# Show the first active quest
	var entry = QuestManager.active.values()[0]
	var quest: Quest = entry.quest
	var progress: Array = entry.progress

	quest_label.text = quest.title

	var lines: PackedStringArray = []
	for i in quest.objectives.size():
		var obj: QuestObjective = quest.objectives[i]
		lines.append("%s: %d/%d" % [obj.description, progress[i], obj.required])
	progress_label.text = "\n".join(lines)

func _on_quest_completed(quest: Quest) -> void:
	quest_label.text = quest.title
	progress_label.text = "Quest complete!"
	await get_tree().create_timer(3.0).timeout
	_refresh()
