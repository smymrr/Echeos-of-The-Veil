extends Node
## HOTKEY DEMO. Hanya untuk mencoba tampilan UI; backend boleh menghapus node ini.
##   E  = demo percakapan (mulai / lanjut)
##   F2 = tampil/sembunyi teks Wave
##   F3 = minimize / buka semua panel HUD + Quest
##   F6 = preview Quest, Boss, Wave, Talk NPC sekaligus
##   F7 = tampil/sembunyi seluruh HUD

const PREVIEW_GROUPS := ["ui_boss", "ui_wave", "ui_npc_talk", "ui_quest"]

var _preview := false


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if UiUtil.input_blocked(get_tree()):
		return
	match event.keycode:
		KEY_E:
			_demo_talk()
		KEY_F2:
			_toggle_group("ui_wave")
		KEY_F3:
			_toggle_all_minimize()
		KEY_F6:
			_toggle_preview()
		KEY_F7:
			_toggle_group("ui_hud")


func _toggle_group(group: String) -> void:
	var n := get_tree().get_first_node_in_group(group) as CanvasLayer
	if n:
		n.visible = not n.visible


func _demo_talk() -> void:
	var cm := get_tree().get_first_node_in_group("ui_dialogue") as ConversationManager
	if cm == null:
		push_warning("ConversationManager (group ui_dialogue) tidak ada di scene")
		return
	if cm.is_talking():
		cm.advance()
	else:
		cm.start(DemoConversation.LINES)


func _toggle_all_minimize() -> void:
	var buttons: Array = []
	for g in ["ui_hud", "ui_quest"]:
		var layer := get_tree().get_first_node_in_group(g)
		if layer:
			buttons.append_array(layer.find_children("MinimizeButton", "Button", true, false))
	if buttons.is_empty():
		return
	var minimize: bool = not buttons[0].button_pressed
	for b in buttons:
		b.button_pressed = minimize


func _toggle_preview() -> void:
	_preview = not _preview
	for g in PREVIEW_GROUPS:
		var n := get_tree().get_first_node_in_group(g) as CanvasLayer
		if n:
			n.visible = _preview
	if _preview:
		get_tree().call_group("ui_boss", "refresh")
