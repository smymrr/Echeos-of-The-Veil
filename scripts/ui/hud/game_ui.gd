extends Node
## OPSIONAL: tipis supaya kode lama yang memanggil GameUI tetap jalan.
## Backend boleh menghapus file ini dan memanggil node/group tujuan langsung.

signal save_requested(slot: int)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_forward_signals.call_deferred()


func toggle_pause() -> void:
	var p := get_tree().get_first_node_in_group("ui_pause") as PauseMenu
	if p:
		p.toggle()


func _forward_signals() -> void:
	var sp := get_tree().get_first_node_in_group("ui_save") as SavePanel
	if sp:
		sp.save_requested.connect(save_requested.emit)
