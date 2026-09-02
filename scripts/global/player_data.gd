extends Node

signal stats_changed

var SAVE_PATH: String = "user://save_game.json"

# Stats
var base_max_health: int = 100
var base_attack: int = 10
var base_defense: int = 5
var base_speed: float = 300.0

var current_health: int

# Modifiers
var attack_modifiers: Dictionary = {}
var defense_modifiers: Dictionary = {}
var speed_modifiers: Dictionary = {}
var max_health_modifiers: Dictionary = {}

var last_position: Vector2

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

func _ready() -> void:
	current_health = get_max_health()

# Getter
func get_max_health() -> int:
	return int(base_max_health * _total_multiplier(max_health_modifiers))

func get_attack() -> int:
	return int(base_attack * _total_multiplier(attack_modifiers))

func get_defense() -> int:
	return int(base_defense * _total_multiplier(defense_modifiers))

func get_speed() -> float:
	return base_speed * _total_multiplier(speed_modifiers)

# Modification
func add_modifier(stat_dict: Dictionary, source: String, multiplier: float) -> void:
	stat_dict[source] = multiplier
	stats_changed.emit()

func remove_modifier(stat_dict: Dictionary, source: String) -> void:
	stat_dict.erase(source)
	stats_changed.emit()

func _total_multiplier(modifiers: Dictionary) -> float:
	var total := 1.0
	for mod in modifiers.values():
		total *= mod
	return total

# Saving
func save_game() -> void:
	var data := {
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
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	
	if (parsed == null):
		push_error("File ini corrupted atau tidak bisa dibaca.")
		return false
	
	var data: Dictionary = parsed
	
	base_max_health = data.get("base_max_health", base_max_health)
	base_attack = data.get("base_attack", base_attack)
	base_defense = data.get("base_defense", base_defense)
	base_speed = data.get("base_speed", base_speed)
	
	current_health = data.get("current_health", 100)
	last_position = Vector2(
		data.get("last_position_x", 0.0),
		data.get("last_position_y", 0.0)
	)
	
	max_health_modifiers = data.get("max_health_modifier", {})
	attack_modifiers = data.get("attack_modifiers", {})
	defense_modifiers = data.get("defense_modifier", {})
	speed_modifiers = data.get("speed_modifiers", {})
	
	story_flags = data.get("story_flags", {})
	current_chapter = data.get("current_chapter", "")
	active_quests = data.get("active_quests", "")
	completed_quests = data.get("completed_quests", {})
	
	equipped_armor = data.get("equipped_armor", {})
	equipped_weapon = data.get("equipped_weapon", {})
	inventory = data.get("inventory", {})
	gold = data.get("gold", 0)
	
	return true
