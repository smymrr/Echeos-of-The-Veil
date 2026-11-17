extends Node
## OPSIONAL: tipis supaya kode lama yang memanggil GameUI tetap jalan.
## Backend boleh menghapus file ini dan memanggil node/group tujuan langsung.

signal choice_made(index: int, text: String)
signal save_requested(slot: int)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_forward_signals.call_deferred()


func toggle_pause() -> void:
	var p := get_tree().get_first_node_in_group("ui_pause") as PauseMenu
	if p:
		p.toggle()


func start_conversation(lines: Array, npc_name: String = "MALACHAR", mc_name: String = "AELINDRA") -> void:
	var cm := get_tree().get_first_node_in_group("ui_dialogue") as ConversationManager
	if cm:
		cm.start(lines, npc_name, mc_name)


func _forward_signals() -> void:
	var cm := get_tree().get_first_node_in_group("ui_dialogue") as ConversationManager
	if cm:
		cm.choice_made.connect(choice_made.emit)
	var sp := get_tree().get_first_node_in_group("ui_save") as SavePanel
	if sp:
		sp.save_requested.connect(save_requested.emit)
