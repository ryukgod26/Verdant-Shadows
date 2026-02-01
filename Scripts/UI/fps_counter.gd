extends Label

func _ready() -> void:
	# Position in top right
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -100
	offset_right = -10
	offset_top = 10
	offset_bottom = 40

	# Dim text (10% opacity)
	add_theme_color_override("font_color", Color(1, 1, 1, 0.1))
	add_theme_font_size_override("font_size", 18)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _process(_delta: float) -> void:
	text = "%d FPS" % Engine.get_frames_per_second()
