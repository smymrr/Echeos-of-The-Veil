extends Node

var SAVE_PATH: String = "user://settings.json"

var volume_settings = {
	"master_volume" = 1.0,
	"music_volume" = 1.0,
	"sfx_volume" = 1.0,
	"ambient_volume" = 1.0,
	"voice_volume" = 1.0,
}

var display_settings = {
	"fullscreen" = true,
	"resolution" = "",
	"vsync" = false,
	"screen_shake" = false,
	"show_fps" = false,
	"brightness" = 0.7
}

var gameplay_settings = {
	"language" = "indonesia",
	"auto_save" = true,
	"show_hints" = true,
	"damage_numbers" = true,
}

var resolution = [
	"1920x1080",
	""
]

func save_data() -> void:
	var data := {
		"volume": {
			"master_volume": volume_settings["master_volume"],
			"music_volume": volume_settings["music_volume"],
			"sfx_volume": volume_settings["sfx_volume"],
			"ambient_volume": volume_settings["ambient_volume"],
			"voice_volume": volume_settings["voice_volume"]
		},
		"display": {
			"fullscreen": display_settings["fullscreen"],
			"resolution": display_settings["resolution"],
			"vsync": display_settings["vsync"],
			"screen_shake": display_settings["screen_shake"],
			"show_fps": display_settings["show_fps"],
			"brightness": display_settings["brightness"]
		},
		"gameplay": {
			"language": gameplay_settings["language"],
			"auto_save": gameplay_settings["auto_save"],
			"show_hints": gameplay_settings["show_hints"],
			"damage_numbers": gameplay_settings["damage_numbers"]
		}
}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func load_data() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	
	if (parsed == null):
		push_error("File ini corrupted atau tidak bisa dibaca.")
		return false
	
	var data: Dictionary = parsed
	
	if data.has("volume"):
		volume_settings.merge(data["volume"], true)
	
	if data.has("display"):
		display_settings.merge(data["display"], true)
	
	if data.has("gameplay"):
		gameplay_settings.merge(data["gameplay"], true)
	
	return true
