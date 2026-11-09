class_name UiUtil
extends RefCounted
## Pengecekan umum untuk input hotkey.


## True kalau kotak pilihan jawaban (group "ui_choice") sedang tampil.
static func choices_open(tree: SceneTree) -> bool:
	var c := tree.get_first_node_in_group("ui_choice") as CanvasLayer
	return c != null and c.visible


## True kalau hotkey biasa (J, I, F1, 1-6, dst) harus diabaikan.
static func input_blocked(tree: SceneTree) -> bool:
	return tree.paused or choices_open(tree)
