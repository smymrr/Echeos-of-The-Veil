extends Node

signal quest_started(quest: Quest)
signal quest_updated(quest: Quest)
signal quest_completed(quest: Quest)

var active: Dictionary = {}          # quest_id -> {"quest": Quest, "progress": Array[int]}
var completed: Array[String] = []

func start_quest(quest: Quest) -> void:
	if active.has(quest.id) or quest.id in completed:
		return
	var progress: Array[int] = []
	progress.resize(quest.objectives.size())
	progress.fill(0)
	active[quest.id] = {"quest": quest, "progress": progress}
	quest_started.emit(quest)

# Call this whenever something happens in the game
func report(type: String, target_id: String, amount: int = 1) -> void:
	for id in active.keys():
		var entry = active[id]
		var quest: Quest = entry.quest
		var i := _current_index(quest, entry.progress)
		if i == -1:
			continue
		var obj := quest.objectives[i]
		if obj.type == type and obj.target_id == target_id:
			entry.progress[i] = min(entry.progress[i] + amount, obj.required)
			quest_updated.emit(quest)
			_check_complete(quest)


## Index of the first unfinished objective, or -1 if all are done.
func _current_index(quest: Quest, progress: Array) -> int:
	for i in quest.objectives.size():
		if progress[i] < quest.objectives[i].required:
			return i
	return -1

func _check_complete(quest: Quest) -> void:
	var progress = active[quest.id].progress
	for i in quest.objectives.size():
		if progress[i] < quest.objectives[i].required:
			return
	active.erase(quest.id)
	completed.append(quest.id)
	quest_completed.emit(quest)
