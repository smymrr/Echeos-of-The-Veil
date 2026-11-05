extends ScrollContainer

func _ready() -> void:
	for slider: HSlider in find_children("*Slider", "HSlider"):
		# Visual Update
		var label_name := slider.name.replace("Slider", "Value")
		var label := find_child(label_name) as Label
		slider_helper.bind_slider_to_label(slider, label)
		
		# AudioBus Update
		var bus_name = slider.name.replace("Slider", "")
		slider.value_changed.connect(func(new_val: float):
			set_volume(bus_name, new_val / 100)
		)

func set_volume(bus_name: String, linear_value: float) -> void:
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
