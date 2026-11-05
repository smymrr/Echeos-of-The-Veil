extends ScrollContainer

@onready var list: BoxContainer = get_node("Margin/List")
@onready var fullscreen_toggle: BaseButton = list.get_node("FullscreenRow/FullscreenToggle")

func _ready() -> void:
	for slider: HSlider in find_children("*Slider", "HSlider"):
		# Visual Update
		var label_name := slider.name.replace("Slider", "Value")
		var label := find_child(label_name) as Label
		slider_helper.bind_slider_to_label(slider, label)
		
		slider.value_changed.connect(func(new_val: float):
			pass
		)
	
	fullscreen_toggle.toggled.connect(toggle_fullscreen)

func toggle_vsync() -> void:
	pass

func toggle_fullscreen(value: bool) -> void:
	var main_window = get_tree().root.get_window()
	if value:
		main_window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	else:
		main_window.mode = Window.MODE_WINDOWED

func toggle_screen_shake() -> void:
	pass

func toggle_fps() -> void:
	pass

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
