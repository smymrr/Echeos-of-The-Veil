extends CanvasLayer

signal step_started(index: int)
signal finished
signal _gate_opened
signal step_completed(index: int)

@export var autostart: bool = true
@export var step_delay: float = 0.6   # pause after a step is completed
@export var fade_time: float = 0.25
@export var skip_action: StringName = &""   # e.g. &"ui_cancel"; empty = can't skip

# ----------------------------------------------------------------
# EDIT YOUR TUTORIAL HERE
#
# "type" (what the step waits for):
#   "actions": player must press Input Map actions
#       "actions": ["move_up", ...]  -> the Input Map actions to press
#       "need": "all" -> every listed action at least once (default)
#               "any" -> just one of them
#   "event":   advances when other code calls notify("event_name")
#       "event": "event_name"        -> the name to wait for
#   "wait":    shows the text for "seconds", then continues
#       "seconds": 3.0
#
# Optional keys (work with any type):
#   "start_on": "event_name"  -> step stays hidden until this event is
#                                announced (e.g. a room trigger)
#   "marker": "waypoint_name" -> shows the waypoint arrow pointing at the
#                                Marker2D with this name (must be in the
#                                "waypoints" group). The arrow hides when
#                                the step is completed. Leave it out for
#                                no arrow.
#
# Example:
# {"text": "Head to the forge", "type": "event",
#     "event": "entered_forge", "marker": "forge"},
# ----------------------------------------------------------------

var steps: Array = [
	#{"text": "Welcome! Let's learn the basics.", "type": "wait", "seconds": 3.0},
	#{"text": "Move around with W A S D", "type": "actions",
	#	"actions": ["move_up", "move_down", "move_left", "move_right"], "need": "all"},
	#{"text": "Press Q to dash", "type": "actions", "actions": ["dash"]},
	#{"text": "Click to attack", "type": "actions", "actions": ["left_click"]},
	{"text": "Your sword follows your mouse!.", "type": "wait", "seconds": 3.0, "unlock": "gate_1"},
	#{"text": "Head to the waypoint", "type": "event", "event": "enter_2nd", "marker": "quest"},
]
# ----------------------------------------------------------------

@onready var panel: Control = $Panel
@onready var label: Label = $Panel/Label

var _index: int = -1
var _running: bool = false
var _accepting: bool = false
var _pending: Array = []
var _total: int = 0
var _base_text: String = ""
var _tween: Tween
var _gate_event: String = ""

func _ready() -> void:
	add_to_group("tutorial")
	panel.modulate.a = 0.0
	_validate_steps()
	await get_tree().process_frame
	if autostart:
		start()

func start() -> void:
	_index = -1
	_running = true
	_next_step()


func notify(event_name: String) -> void:
	if not _running:
		return
	# A step is waiting for this room/event to start
	if _gate_event != "" and event_name == _gate_event:
		_gate_event = ""
		_gate_opened.emit()
		return
	if not _accepting:
		return
	var step: Dictionary = steps[_index]
	if step.get("type", "") == "event" and step.get("event", "") == event_name:
		_complete_step()


func _input(event: InputEvent) -> void:
	if not _running:
		return
	if skip_action != &"" and event.is_action_pressed(skip_action):
		_finish()
		return
	if not _accepting or event.is_echo():
		return

	var step: Dictionary = steps[_index]
	if step.get("type", "actions") != "actions":
		return

	for action in _pending.duplicate():
		if event.is_action_pressed(action):
			_pending.erase(action)

	if step.get("need", "all") == "any":
		if _pending.size() < _total:
			_complete_step()
	elif _pending.is_empty():
		_complete_step()
	else:
		_update_label()


func _next_step() -> void:
	_index += 1
	if _index >= steps.size():
		_finish()
		return

	var step: Dictionary = steps[_index]
	_accepting = false

	# Hold here until the trigger event arrives
	var gate: String = step.get("start_on", "")
	if gate != "":
		_gate_event = gate
		await _gate_opened
		if not _running:
			return

	_pending = step.get("actions", []).duplicate()
	_total = _pending.size()
	_base_text = step.get("text", "")
	var targets = get_tree().get_nodes_in_group("waypoint_marker")
	get_tree().call_group("waypoint_marker", "point_to", step.get("marker", ""))
	_update_label()
	step_started.emit(_index)

	await _fade(1.0)
	if not _running:
		return
	_accepting = true

	if step.get("type", "actions") == "wait":
		await get_tree().create_timer(step.get("seconds", 3.0)).timeout
		_complete_step()


func _complete_step() -> void:
	if not _accepting:
		return
	
	_accepting = false
	get_tree().call_group("waypoint_marker", "point_to", "")
	
	var unlock_id: String = steps[_index].get("unlock", "")
	if unlock_id != "":
		get_tree().call_group("tutorial_barrier", "unlock", unlock_id)
	
	step_completed.emit(_index)
	
	if steps[_index].get("type", "actions") != "wait":
		label.text = "✓ " + _base_text
	
	await get_tree().create_timer(step_delay).timeout
	await _fade(0.0)
	
	if _running:
		_next_step()

func _finish() -> void:
	_running = false
	_accepting = false
	
	get_tree().call_group("waypoint_marker", "point_to", "")
	
	_gate_event = ""
	_gate_opened.emit()   # releases a step that's still waiting, e.g. after a skip
	
	await _fade(0.0)
	
	finished.emit()


func _update_label() -> void:
	var step: Dictionary = steps[_index]
	var text := _base_text
	if step.get("type", "actions") == "actions" and step.get("need", "all") == "all" and _total > 1:
		text += "  (%d/%d)" % [_total - _pending.size(), _total]
	label.text = text


func _fade(alpha: float) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(panel, "modulate:a", alpha, fade_time)
	await _tween.finished


func _validate_steps() -> void:
	for step in steps:
		for action in step.get("actions", []):
			if not InputMap.has_action(action):
				push_warning("Tutorial: action '%s' is not in the Input Map" % action)
