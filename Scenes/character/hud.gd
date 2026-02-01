extends Control

var distance_meters := 0.0
var coin_count := 0

var distance_label: Label
var coin_label: Label
var melon_font: Font

# Boost bar
var boost_container: Control
var boost_bar_bg: ColorRect
var boost_bar_fill: ColorRect
var boost_label: Label
var boost_max_duration := 5.0

func _ready():
	melon_font = load("res://assets/fonts/melon-pop.ttf")
	
	anchor_left = 0
	anchor_top = 0
	anchor_right = 1
	anchor_bottom = 1
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	
	_create_ui()
	_create_boost_bar()

func _create_ui():
	# Distance - top center
	distance_label = Label.new()
	distance_label.text = "0 m"
	if melon_font:
		distance_label.add_theme_font_override("font", melon_font)
	distance_label.add_theme_font_size_override("font_size", 36)
	distance_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	distance_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	distance_label.add_theme_constant_override("shadow_offset_x", 2)
	distance_label.add_theme_constant_override("shadow_offset_y", 2)
	distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	distance_label.anchor_left = 0.5
	distance_label.anchor_right = 0.5
	distance_label.anchor_top = 0
	distance_label.offset_left = -100
	distance_label.offset_right = 100
	distance_label.offset_top = 20
	add_child(distance_label)
	
	# Coins - top left
	var coin_container = HBoxContainer.new()
	coin_container.anchor_left = 0
	coin_container.anchor_top = 0
	coin_container.offset_left = 20
	coin_container.offset_top = 20
	add_child(coin_container)
	
	var coin_icon = Label.new()
	coin_icon.text = "●"
	coin_icon.add_theme_font_size_override("font_size", 72)
	coin_icon.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	coin_container.add_child(coin_icon)
	
	coin_label = Label.new()
	coin_label.text = " 0"
	if melon_font:
		coin_label.add_theme_font_override("font", melon_font)
	coin_label.add_theme_font_size_override("font_size", 36)
	coin_label.add_theme_color_override("font_color", Color.WHITE)
	coin_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	coin_label.add_theme_constant_override("shadow_offset_x", 2)
	coin_label.add_theme_constant_override("shadow_offset_y", 2)
	coin_container.add_child(coin_label)

func update_distance(meters: float):
	distance_meters = meters
	if distance_label:
		distance_label.text = str(int(meters)) + " m"

func update_coins(total: int):
	coin_count = total
	if coin_label:
		coin_label.text = " " + str(total)

func _create_boost_bar():
	boost_container = Control.new()
	boost_container.anchor_left = 0.5
	boost_container.anchor_right = 0.5
	boost_container.anchor_top = 1
	boost_container.anchor_bottom = 1
	boost_container.offset_left = -150
	boost_container.offset_right = 150
	boost_container.offset_top = -60
	boost_container.offset_bottom = -20
	boost_container.visible = false
	add_child(boost_container)
	
	# Background bar
	boost_bar_bg = ColorRect.new()
	boost_bar_bg.color = Color(0.1, 0.15, 0.25, 0.8)
	boost_bar_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	boost_container.add_child(boost_bar_bg)
	
	# Fill bar
	boost_bar_fill = ColorRect.new()
	boost_bar_fill.color = Color(0.2, 0.6, 1.0, 0.9)
	boost_bar_fill.anchor_left = 0
	boost_bar_fill.anchor_top = 0
	boost_bar_fill.anchor_right = 1
	boost_bar_fill.anchor_bottom = 1
	boost_bar_fill.offset_left = 4
	boost_bar_fill.offset_top = 4
	boost_bar_fill.offset_right = -4
	boost_bar_fill.offset_bottom = -4
	boost_container.add_child(boost_bar_fill)
	
	# Label
	boost_label = Label.new()
	boost_label.text = "BOOST"
	if melon_font:
		boost_label.add_theme_font_override("font", melon_font)
	boost_label.add_theme_font_size_override("font_size", 20)
	boost_label.add_theme_color_override("font_color", Color.WHITE)
	boost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	boost_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	boost_container.add_child(boost_label)

func show_boost_bar(duration: float):
	boost_max_duration = duration
	boost_container.visible = true
	boost_bar_fill.anchor_right = 1.0
	
	# Fade in
	boost_container.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(boost_container, "modulate:a", 1.0, 0.2)

func update_boost_bar(remaining: float):
	if boost_bar_fill and boost_max_duration > 0:
		var fill_ratio = remaining / boost_max_duration
		boost_bar_fill.anchor_right = clamp(fill_ratio, 0.0, 1.0)
		
		# Pulse when low
		if fill_ratio < 0.3:
			var pulse = 0.7 + sin(Time.get_ticks_msec() * 0.01) * 0.3
			boost_bar_fill.color = Color(0.2, 0.6, 1.0, pulse)

func hide_boost_bar():
	var tween = create_tween()
	tween.tween_property(boost_container, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): boost_container.visible = false)
