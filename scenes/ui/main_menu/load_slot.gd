class_name LoadSlot
extends BaseButton

signal slot_selected(slot_index: int)

@onready var slot_number_label: Label = find_child("SlotNumber", true, false) as Label
@onready var slot_name_label: Label = find_child("SlotName", true, false) as Label
@onready var location_label: Label = find_child("Location", true, false) as Label
@onready var play_time_label: Label = find_child("PlayTime", true, false) as Label
@onready var saved_date_label: Label = find_child("SaveDate", true, false) as Label
@onready var empty_label: Label = find_child("EmptyLabel", true, false) as Label

var slot_index: int = 1
var has_data: bool = false


func _ready() -> void:
	pressed.connect(_on_pressed)


func setup(index: int, data: Dictionary) -> void:
	slot_index = index
	slot_number_label.text = str(index)
	has_data = not data.is_empty()

	if not has_data:
		slot_name_label.text = "N/A"
		location_label.text = "N/A"
		play_time_label.text = "--:--"
		saved_date_label.text = "N/A"
		disabled = true
		if empty_label:
			empty_label.visible = false
		return

	disabled = false
	if empty_label:
		empty_label.visible = false
	if saved_date_label:
		saved_date_label.text = str(data.get("saved_date", "N/A"))
	
	# Use saved title/chapter if present, otherwise fall back to "N/A"
	var title: String = str(data.get("slot_name", ""))
	if title == "":
		title = str(data.get("current_chapter", ""))
	slot_name_label.text = title if title != "" else "N/A"

	var map_name: String = str(data.get("current_map", ""))
	location_label.text = map_name.capitalize() if map_name != "" else "N/A"

	play_time_label.text = _format_play_time(float(data.get("play_time", 0.0)))
	saved_date_label.text = str(data.get("saved_date", "N/A"))

func _format_play_time(seconds: float) -> String:
	if seconds <= 0.0:
		return "N/A"
	var total := int(seconds)
	var hours := total / 3600
	var minutes := (total % 3600) / 60
	return "%02d:%02d" % [hours, minutes]


func _on_pressed() -> void:
	if has_data:
		slot_selected.emit(slot_index)
