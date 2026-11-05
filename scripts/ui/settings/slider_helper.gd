class_name slider_helper
# Memperbarui tampilan label persentase (XValue) saat slider (XSlider) digeser.

static func bind_slider_to_label(slider: HSlider, label: Label) -> void:
	if not label:
		return

	# Helper untuk update teks
	var update_text := func(value: float) -> void:
		label.text = "%d%%" % int(value)

	# Set nilai awal dan hubungkan sinyal
	update_text.call(slider.value)
	slider.value_changed.connect(update_text)

static func bind_brightness_slider_to_label(value: float, label: Label) -> void:
	if value == 0:
		label.text = "Dim"
	elif value == 50:
		label.text = "Normal"
	elif value == 100:
		label.text = "Bright"
	else:
		label.text = "%d%%" % int(value)
