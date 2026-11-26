extends ColorRect


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	var mat := material as ShaderMaterial
	if cam == null or mat == null:
		return
	var view := get_viewport_rect().size / cam.zoom
	var top_left := cam.get_screen_center_position() - view * 0.5
	mat.set_shader_parameter("view_size", view)
	mat.set_shader_parameter("world_offset", top_left)
