extends ScrollContainer

@onready var list: BoxContainer = get_node("Margin/List")
@onready var fullscreen_toggle: BaseButton = list.get_node("FullscreenRow/FullscreenToggle")
@onready var vsync_toggle: BaseButton = list.get_node("VsyncRow/VsyncToggle")
@onready var fps_toggle: BaseButton = list.get_node("ShowFpsRow/ShowFpsToggle")

func _ready() -> void:
	for slider: HSlider in find_children("*Slider", "HSlider"):
		# Visual Update
		var label_name := slider.name.replace("Slider", "Value")
		var label := find_child(label_name) as Label
		slider_helper.bind_slider_to_label(slider, label)
		
		slider.value_changed.connect(func(new_val: float):
			if new_val == 0:
				Brightness.environment.adjustment_brightness = 0.7
				label.text = "Dim"
			elif new_val == 25:
				Brightness.environment.adjustment_brightness = 0.85
			elif new_val == 50:
				Brightness.environment.adjustment_brightness = 1
			elif new_val == 75:
				Brightness.environment.adjustment_brightness = 1.25
			elif new_val == 100:
				Brightness.environment.adjustment_brightness = 1.5
				label.text = "Bright"
		)
	
	fullscreen_toggle.toggled.connect(toggle_fullscreen)
	vsync_toggle.toggled.connect(toggle_vsync)
	fps_toggle.toggled.connect(toggle_fps)

func toggle_vsync(value: bool) -> void:
	if value:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func toggle_fullscreen(value: bool) -> void:
	var main_window = get_tree().root.get_window()
	if value:
		main_window.mode = Window.MODE_FULLSCREEN
	else:
		main_window.mode = Window.MODE_WINDOWED

func toggle_screen_shake() -> void:
	pass

func toggle_fps(value: bool) -> void:
	if value:
		FpsDisplay.visible = true
		print("true")
	else:
		FpsDisplay.visible = false

func set_resolution(bus_name: String, linear_value: float) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	
	# Sanity check
	if bus_index == -1:
		push_warning("Audio bus not found: " + bus_name)
		return

	# Change audio value# 2. Check if the slider is essentially at 0 to completely mute
	if linear_value <= 0.001:
		AudioServer.set_bus_mute(bus_index, true)
		print("Muted")
	else:
		AudioServer.set_bus_mute(bus_index, false)
		# 3. Convert 0.0 - 1.0 to decibels and apply
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(linear_value))
		print("New " + bus_name + " volume: ", AudioServer.get_bus_volume_linear(bus_index))

func set_brightness() -> void:
	pass
