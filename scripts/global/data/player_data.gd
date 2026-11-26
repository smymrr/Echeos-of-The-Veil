extends Node

signal stats_changed

var SAVE_PATH: String = "user://save_slot_1.json"
var player: CharacterBody2D

# Stats
var base_max_health: int = 100
var base_attack: int = 100
var base_defense: int = 5
var base_speed: float = 500.0

var current_health: int

# Modifiers
var attack_modifiers: Dictionary = {}
var defense_modifiers: Dictionary = {}
var speed_modifiers: Dictionary = {}
var max_health_modifiers: Dictionary = {}

var last_position: Vector2 = Vector2(50, 10)
var current_map: String = ""
var tutorial_shown: bool = false
# Story
# Story / Quests
var story_flags: Dictionary = {}
var current_chapter: String = ""

var active_quests: Dictionary = {}
# shape: { quest_id: { objective_id: current_count } }
# e.g. { "slime_hunt": { "kill_slimes": 3 } }

var completed_quests: Array = []
# e.g. ["intro_quest", "find_the_key"]

# Inventory
var inventory: Dictionary = {}
var gold: int = 0
var equipped_weapon: String = ""
var equipped_armor: Dictionary = {}

var current_slot: int = 1
var slot_name: String = ""
var play_time: float = 0.0

func _ready() -> void:
	current_health = get_max_health()

func _process(delta: float) -> void:
	if player != null:
		last_position = player.position
		play_time += delta

# Getter
func get_max_health() -> int:
	var flat_bonus: int = int(_get_flat_bonus(max_health_modifiers))
	var multi_bonus: float = _get_multiplier(max_health_modifiers)
	
	return (int(base_max_health + flat_bonus) * multi_bonus)

func get_attack() -> int:
	var flat_bonus: int = int(_get_flat_bonus(attack_modifiers))
	var multi_bonus: float = _get_multiplier(attack_modifiers)
	
	return (int(base_attack + flat_bonus) * multi_bonus)

func get_defense() -> int:
	var flat_bonus: int = int(_get_flat_bonus(defense_modifiers))
	var multi_bonus: float = _get_multiplier(defense_modifiers)
	
	return (int(base_defense + flat_bonus) * multi_bonus)

func get_speed() -> float:
	var flat_bonus: int = int(_get_flat_bonus(speed_modifiers))
	var multi_bonus: float = _get_multiplier(speed_modifiers)
	
	return (int(base_speed + flat_bonus) * multi_bonus)

# Modification
func add_modifier(stat_dict: Dictionary, source: String, modifier: float) -> void:
	stat_dict[source] = modifier
	stats_changed.emit()

func remove_modifier(stat_dict: Dictionary, source: String) -> void:
	stat_dict.erase(source)
	stats_changed.emit()

func _get_flat_bonus(modifiers: Dictionary) -> float:
	var total: float = 0.0
	for mod in modifiers:
		if mod.contains("add"):
			total += modifiers[mod]
	return total

func _get_multiplier(modifiers: Dictionary) -> float:
	var total := 1.0
	for mod in modifiers:
		if mod.contains("multi"):
			total *= modifiers[mod]
	return total

# Saving
# Add near your top variables in player_data.gd


func get_slot_path(slot: int) -> String:
	if slot <= 0:
		return SAVE_PATH
	return "user://save_slot_%d.json" % slot


func save_game(slot: int = current_slot) -> void:
	current_slot = slot
	var data := {
		"slot_name": slot_name if slot_name != "" else current_chapter,
		"current_map": current_map,
		"play_time": play_time,
		"saved_date": Time.get_date_string_from_system(),

		"base_max_health": base_max_health,
		"base_attack": base_attack,
		"base_defense": base_defense,
		"base_speed": base_speed,

		"current_health": current_health,
		"last_position_x": last_position.x,
		"last_position_y": last_position.y,

		"max_health_modifiers": max_health_modifiers,
		"attack_modifiers": attack_modifiers,
		"defense_modifiers": defense_modifiers,
		"speed_modifiers": speed_modifiers,

		"story_flags": story_flags,
		"current_chapter": current_chapter,
		"active_quests": active_quests,
		"completed_quests": completed_quests,

		"equipped_armor": equipped_armor,
		"equipped_weapon": equipped_weapon,
		"inventory": inventory,
		"gold": gold
	}

	var file := FileAccess.open(get_slot_path(slot), FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func load_game(slot: int = 1) -> bool:
	var path := get_slot_path(slot)
	if not FileAccess.file_exists(path) and slot == 1:
		path = SAVE_PATH
	if not FileAccess.file_exists(path):
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()

	if parsed == null or not (parsed is Dictionary):
		push_error("File ini corrupted atau tidak bisa dibaca.")
		return false

	var data: Dictionary = parsed
	current_slot = slot
	slot_name = data.get("slot_name", "")
	current_map = data.get("current_map", "")
	play_time = data.get("play_time", 0.0)

	base_max_health = data.get("base_max_health", base_max_health)
	base_attack = data.get("base_attack", base_attack)
	base_defense = data.get("base_defense", base_defense)
	base_speed = data.get("base_speed", base_speed)

	current_health = data.get("current_health", base_max_health)
	last_position = Vector2(
		data.get("last_position_x", 0.0),
		data.get("last_position_y", 0.0)
	)

	if player != null:
		player.position = last_position

	max_health_modifiers = data.get("max_health_modifiers", {})
	attack_modifiers = data.get("attack_modifiers", {})
	defense_modifiers = data.get("defense_modifiers", {})
	speed_modifiers = data.get("speed_modifiers", {})

	story_flags = data.get("story_flags", {})
	current_chapter = data.get("current_chapter", "")
	active_quests = data.get("active_quests", {})
	completed_quests = data.get("completed_quests", [])

	equipped_armor = data.get("equipped_armor", {})
	equipped_weapon = data.get("equipped_weapon", {})
	inventory = data.get("inventory", {})
	gold = data.get("gold", 0)

	return true

func has_save_in_slot(slot: int) -> bool:
	if FileAccess.file_exists(get_slot_path(slot)):
		return true
	return slot == 1 and FileAccess.file_exists(SAVE_PATH)


func are_slots_full(max_slots: int = 4) -> bool:
	for i in range(1, max_slots + 1):
		if not has_save_in_slot(i):
			return false
	return true


func get_first_empty_slot(max_slots: int = 4) -> int:
	for i in range(1, max_slots + 1):
		if not has_save_in_slot(i):
			return i
	return 1


func start_new_game(slot: int = 0, max_slots: int = 4) -> int:
	var target_slot := slot if slot > 0 else get_first_empty_slot(max_slots)

	# Delete existing save file if overwriting
	var slot_path := get_slot_path(target_slot)
	if FileAccess.file_exists(slot_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path))
	if target_slot == 1 and FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

	# Reset stats, progress, and inventory to defaults
	current_slot = target_slot
	slot_name = "Journey %d" % target_slot
	play_time = 0.0

	base_max_health = 100
	base_attack = 100
	base_defense = 5
	base_speed = 500.0
	max_health_modifiers.clear()
	attack_modifiers.clear()
	defense_modifiers.clear()
	speed_modifiers.clear()
	current_health = get_max_health()

	last_position = Vector2(50, 10)
	current_map = "tutorial_dungeon"
	tutorial_shown = false

	story_flags.clear()
	current_chapter = "Chapter 1"
	active_quests.clear()
	completed_quests.clear()

	inventory.clear()
	gold = 0
	equipped_weapon = ""
	equipped_armor.clear()

	if CheckpointManager:
		CheckpointManager.clear()

	# Write the initial save file so the slot is immediately occupied
	save_game(target_slot)
	return target_slot
