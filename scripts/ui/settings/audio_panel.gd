extends ScrollContainer

func _ready() -> void:
	for slider: HSlider in find_children("*Slider", "HSlider"):
		# Load
		var bus_name = slider.name.replace("Slider", "")
		slider.value = PlayerSettings.get_setting("Audio", bus_name, 100)
		
		# Visual Update
		var label_name := slider.name.replace("Slider", "Value")
		var label := find_child(label_name) as Label
		slider_helper.bind_slider_to_label(slider, label)
		
		# AudioBus Update
		slider.value_changed.connect(func(new_val: float):
			PlayerSettings.save_setting("Audio", bus_name, new_val)
		);
