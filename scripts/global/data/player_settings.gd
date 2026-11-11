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
	get_window().unresizable = true
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
		elif key == "resolution":
			if get_tree().root.get_window().mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
				return
			
			if value == 0: # 1152x648
				DisplayServer.window_set_size(Vector2i(1152, 648))
			elif value == 1: # 1280x720
				DisplayServer.window_set_size(Vector2i(1280, 720))
			elif value == 2: # 1920x1080
				DisplayServer.window_set_size(Vector2i(1920, 1080))
			
			center_window()
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

func center_window() -> void:
	# Get the monitor the game window is currently on (supports multi-monitor setups)
	var current_screen: int = DisplayServer.window_get_current_screen()
	var screen_pos: Vector2i = DisplayServer.screen_get_position(current_screen)
	var screen_size: Vector2i = DisplayServer.screen_get_size(current_screen)
	
	# Use window_get_size_with_decorations() so the title bar doesn't push the window slightly low
	var window_size: Vector2i = DisplayServer.window_get_size_with_decorations()
	
	# Calculate and apply the centered position
	var centered_pos: Vector2i = screen_pos + (screen_size - window_size) / 2
	DisplayServer.window_set_position(centered_pos)
