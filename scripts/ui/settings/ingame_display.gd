extends ScrollContainer

@onready var list: BoxContainer = get_node("Margin/List")
@onready var fullscreen_toggle: BaseButton = list.get_node("FullscreenRow/FullscreenToggle")
@onready var vsync_toggle: BaseButton = list.get_node("VsyncRow/VsyncToggle")
@onready var fps_toggle: BaseButton = list.get_node("ShowFpsRow/ShowFpsToggle")
@onready var resolution: OptionButton = list.get_node("ResolutionRow/ResolutionOption")

func _ready() -> void:
	# Load
	fullscreen_toggle.button_pressed = PlayerSettings.get_setting("Display", "fullscreen", true)
	vsync_toggle.button_pressed = PlayerSettings.get_setting("Display", "vsync", true)
	fps_toggle.button_pressed = PlayerSettings.get_setting("Display", "fps", false)
	resolution.select(PlayerSettings.get_setting("Display", "resolution", 2))
	
	if fullscreen_toggle.button_pressed:
		resolution.disabled = true
	
	# Slider
	for slider: HSlider in find_children("*Slider", "HSlider"):
		# Visual Update
		var label_name := slider.name.replace("Slider", "Value")
		var label := find_child(label_name) as Label
		
		# Load
		slider.value = PlayerSettings.get_setting("Display", "brightness", 50)
		slider_helper.bind_brightness_slider_to_label(slider.value, label)
		
		# Update
		slider.value_changed.connect(func(new_val: float):
			PlayerSettings.save_setting("Display", "brightness", new_val)
			slider_helper.bind_brightness_slider_to_label(new_val, label)
		)
	
	# Toggles
	fullscreen_toggle.toggled.connect(toggle_fullscreen)
	vsync_toggle.toggled.connect(toggle_vsync)
	fps_toggle.toggled.connect(toggle_fps)
	
	resolution.item_selected.connect(set_resolution)

func toggle_vsync(value: bool) -> void:
	PlayerSettings.save_setting("Display", "vsync", value)

func toggle_fullscreen(value: bool) -> void:
	resolution.disabled = value
	PlayerSettings.save_setting("Display", "fullscreen", value)

func set_resolution(index) -> void:
	var selected_id: int = resolution.get_item_id(index)
	PlayerSettings.save_setting("Display", "resolution", selected_id)

func toggle_screen_shake() -> void:
	pass

func toggle_fps(value: bool) -> void:
	PlayerSettings.save_setting("Display", "fps", value)
