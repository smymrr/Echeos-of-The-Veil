extends Node

const SAVE_PATH = "user://settings.cfg"
var config := ConfigFile.new()

func _ready() -> void:
	load_settings()

func save_setting(section: String, key: String, value: Variant) -> void:
	config.set_value(section, key, value)
	config.save(SAVE_PATH)
	_apply_setting(section, key, value)

func load_settings() -> void:
	# Default
	if config.load(SAVE_PATH) != OK:
		return 

	# Setting application
	for section in config.get_sections():
		for key in config.get_section_keys(section):
			_apply_setting(section, key, config.get_value(section, key))

# Handles saved data routing to Godot servers
func _apply_setting(section: String, key: String, value: Variant) -> void:
	if section == "Audio":
		var bus_idx := AudioServer.get_bus_index(key)
		var normalized_value = value / 100
		if bus_idx != -1:
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(normalized_value))
			AudioServer.set_bus_mute(bus_idx, normalized_value <= 0.001)
			
	elif section == "Display":
		if key == "fullscreen":
			var mode = DisplayServer.WINDOW_MODE_FULLSCREEN if value else DisplayServer.WINDOW_MODE_WINDOWED
			var main_window = get_tree().root.get_window()
			
			main_window.mode = mode
		elif key == "vsync":
			var mode = DisplayServer.VSyncMode.VSYNC_ENABLED if value else DisplayServer.VSyncMode.VSYNC_DISABLED
			DisplayServer.window_set_vsync_mode(mode)
		elif key == "fps":
			FpsDisplay.visible = value
		elif key == "brightness":
			if value == 0:
				Brightness.environment.adjustment_brightness = 0.75
			elif value == 25:
				Brightness.environment.adjustment_brightness = 0.85
			elif value == 50:
				Brightness.environment.adjustment_brightness = 1
			elif value == 75:
				Brightness.environment.adjustment_brightness = 1.25
			elif value == 100:
				Brightness.environment.adjustment_brightness = 1.5

# UI Helper
func get_setting(section: String, key: String, default_val: Variant) -> Variant:
	return config.get_value(section, key, default_val)
