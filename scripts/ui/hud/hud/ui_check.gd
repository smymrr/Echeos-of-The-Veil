extends Node
## SEMENTARA: cek pemasangan UI. Hasilnya tampil LANGSUNG DI LAYAR game (kiri atas),
## jadi tidak perlu membuka panel Output. Hapus node ini setelah selesai.
##   ESC / tombol lain = dicatat di baris KEY
##   F9                = paksa buka/tutup Pause (untuk memisahkan "input tidak sampai"
##                       dengan "panel Pause tidak tampil")

const GROUPS := [
	"ui_hud", "ui_quest", "ui_inventory", "ui_boss", "ui_pause", "ui_options",
	"ui_save", "ui_npc_talk", "ui_mc_talk", "ui_choice", "ui_dialogue", "ui_wave",
]

@export var font_size := 10

var _label: Label
var _report := ""
var _last_key := "-"
var _f9_note := "-"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 128
	add_child(layer)
	_label = Label.new()
	_label.position = Vector2(8, 8)
	_label.add_theme_font_size_override("font_size", font_size)
	_label.add_theme_color_override("font_color", Color.YELLOW)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	layer.add_child(_label)
	await get_tree().process_frame
	_build_report()


func _build_report() -> void:
	var lines: PackedStringArray = ["== UI CHECK =="]
	for g in GROUPS:
		var n := get_tree().get_first_node_in_group(g)
		if n == null:
			lines.append("MISSING  %s" % g)
			continue
		var s := n.get_script() as Script
		var script_name: String = s.resource_path.get_file() if s else "(TIDAK ADA SCRIPT)"
		lines.append("OK  %s  [%s]  %s" % [g, script_name, n.name])
	var am := get_tree().root.get_node_or_null("AudioManager")
	lines.append("AudioManager autoload: %s" % ("ada" if am else "tidak ada (pakai fallback)"))
	lines.append("Pilihan jawaban menutup hotkey: %s" % UiUtil.choices_open(get_tree()))
	_report = "\n".join(lines)


func _process(_delta: float) -> void:
	if _label == null:
		return
	var pause_info := "ui_pause: tidak ada"
	var p := get_tree().get_first_node_in_group("ui_pause")
	if p:
		var root := p.get_node_or_null("Root") as CanvasItem
		var menu := p.get_node_or_null("Root/PausePanel") as CanvasItem
		pause_info = "ui_pause.visible=%s | Root=%s | Root/PausePanel=%s" % [
			p.get("visible"),
			("tidak ada" if root == null else str(root.visible)),
			("tidak ada" if menu == null else str(menu.visible)),
		]
	_label.text = "%s\n%s\nKEY: %s | paused=%s | blocked=%s\nF9: %s" % [
		_report, pause_info, _last_key, get_tree().paused,
		UiUtil.input_blocked(get_tree()), _f9_note,
	]


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	_last_key = OS.get_keycode_string(event.keycode)
	if event.keycode == KEY_F9:
		var pm := get_tree().get_first_node_in_group("ui_pause") as PauseMenu
		if pm == null:
			_f9_note = "PauseMenu tidak ditemukan (script belum terpasang di pause_panel)"
		else:
			pm.toggle()
			_f9_note = "toggle() dipanggil"
