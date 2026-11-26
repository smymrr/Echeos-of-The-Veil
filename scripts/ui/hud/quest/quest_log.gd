extends CanvasLayer
## Quest Log. Pasang di node QuestLog (CanvasLayer). Tombol J buka/tutup.
## Isi quest diambil dari QuestManager (signal quest_started / quest_updated / quest_completed).
## Template: node QuestTitle dan Objective di scene digandakan untuk tiap quest dan objective.

const GROUP := "ui_quest"

@export var show_when_empty: bool = false      # panel tetap tampil walau tidak ada quest
@export var completed_hold_time: float = 2.5   # berapa lama quest selesai tetap terlihat
@export var done_color: Color = Color(0.6, 0.9, 0.6)
@export var open_on_quest_start: bool = false  # buka log otomatis saat quest baru dimulai

@onready var panel: Control = $Root/QuestPanel
@onready var body: Control = $Root/QuestPanel/Content/Body
@onready var title_template: Label = $Root/QuestPanel/Content/Body/QuestTitle
@onready var objective_template: Control = $Root/QuestPanel/Content/Body/Objective
@onready var minimize_button: Button = $Root/QuestPanel/Content/HeaderRow/MinimizeButton
@export var advance_delay: float = 0.5   # pause between crossing out and showing the next objective

const STRIKE_THICKNESS := 2.0

var _seen: Dictionary = {}   # "quest_id:index" -> true, rows that have been shown once
var _generated: Array[Node] = []
var _finished: Array = []       # quest yang baru selesai, ditampilkan sebentar
var _minimized: bool = false


func _ready() -> void:
	add_to_group(GROUP)

	title_template.visible = false
	objective_template.visible = false

	minimize_button.pressed.connect(_toggle_minimized)
	QuestManager.quest_started.connect(_on_quest_started)
	QuestManager.quest_updated.connect(_on_quest_changed)
	QuestManager.quest_completed.connect(_on_quest_completed)

	_refresh()   # kalau sudah ada quest aktif saat scene ini dimuat


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_J and not UiUtil.input_blocked(get_tree()):
		toggle()

func toggle() -> void:
	visible = not visible

func open() -> void:
	visible = true

func close() -> void:
	visible = false

# --- Quest signals -------------------------------------------------

func _on_quest_started(_quest) -> void:
	_refresh()
	if open_on_quest_start:
		open()


func _on_quest_changed(_quest) -> void:
	_refresh()


func _on_quest_completed(quest) -> void:
	_finished.append(quest)
	_refresh()
	await get_tree().create_timer(completed_hold_time).timeout
	_finished.erase(quest)
	_refresh()


# --- Minimize button -----------------------------------------------

func _toggle_minimized() -> void:
	_minimized = not _minimized
	body.visible = not _minimized
	minimize_button.text = "+" if _minimized else "-"   # hapus kalau tombolnya pakai icon


# --- Building the list ---------------------------------------------

func _refresh() -> void:
	_clear()
	var any := false

	for entry in QuestManager.active.values():
		_add_quest(entry.quest, entry.progress, false)
		any = true
	for quest in _finished:
		_add_quest(quest, [], true)
		any = true

	panel.visible = any or show_when_empty


func _clear() -> void:
	for node in _generated:
		if is_instance_valid(node):
			node.get_parent().remove_child(node)
			node.queue_free()
	_generated.clear()


func _add_quest(quest, progress: Array, finished: bool) -> void:
	var title := title_template.duplicate() as Label
	title.visible = true
	title.text = _quest_title(quest) + (" - Complete" if finished else "")
	title.modulate = done_color if finished else Color.WHITE
	body.add_child(title)
	_generated.append(title)

	# Show every finished objective plus the current one, never the future ones
	var last = quest.objectives.size() - 1 if finished else _last_visible_index(quest, progress)

	for i in range(last + 1):
		var obj = quest.objectives[i]
		var current: int = obj.required if finished else progress[i]
		var key := "%s:%d" % [quest.id, i]
		var is_new := not _seen.has(key)
		_seen[key] = true
		_add_objective_row(_objective_text(obj, current), current >= obj.required,
				is_new, advance_delay if i > 0 else 0.0)


## Index of the first unfinished objective (the one the player is working on).
func _last_visible_index(quest, progress: Array) -> int:
	for i in quest.objectives.size():
		if progress[i] < quest.objectives[i].required:
			return i
	return quest.objectives.size() - 1


func _add_objective_row(text: String, done: bool, animate: bool, delay: float) -> void:
	var row := objective_template.duplicate() as Control
	row.visible = true
	body.add_child(row)
	_generated.append(row)

	# The first Label in the row gets the text
	var labels := row.find_children("*", "Label", true, false)
	if not labels.is_empty():
		var label := labels[0] as Label
		label.text = text
		if done:
			label.modulate = done_color
			_strike(label)

	# Optional: tick a CheckBox when the objective is done
	var checks := row.find_children("*", "CheckBox", true, false)
	if not checks.is_empty():
		var check := checks[0] as CheckBox
		check.button_pressed = done
		check.focus_mode = Control.FOCUS_NONE
		check.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# New objectives fade in after a short pause, so the crossing-out is seen first
	if animate:
		row.modulate.a = 0.0
		var tween := row.create_tween()
		tween.tween_interval(delay)
		tween.tween_property(row, "modulate:a", 1.0, 0.25)

## A Label can't strike text through, so draw a thin line across it.
func _strike(label: Label) -> void:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var text_size := font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)

	var line := ColorRect.new()
	line.color = Color.WHITE   # the label's modulate already tints it
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.size = Vector2(text_size.x, STRIKE_THICKNESS)
	line.position = Vector2(0, text_size.y * 0.5)
	label.add_child(line)


func _quest_title(quest) -> String:
	for prop in ["title", "display_name"]:
		if prop in quest and str(quest.get(prop)) != "":
			return str(quest.get(prop))
	return str(quest.id).capitalize()


func _objective_text(obj, current: int) -> String:
	var text := ""
	for prop in ["description", "text", "label"]:
		if prop in obj and str(obj.get(prop)) != "":
			text = str(obj.get(prop))
			break
	if text == "":
		text = "%s %s" % [str(obj.type).capitalize(), str(obj.target_id).capitalize()]
	if obj.required > 1:
		text += " (%d/%d)" % [current, obj.required]
	return text
