extends Control

var distance_meters := 0.0
var coin_count := 0

var distance_label: Label
var coin_label: Label
var melon_font: Font

func _ready():
	# Load font
	melon_font = load("res://assets/fonts/melon-pop.ttf")
	
	# Full screen
	anchor_left = 0
	anchor_top = 0
	anchor_right = 1
	anchor_bottom = 1
	offset_left = 0
	offset_top = 0
	offset_right = 0
	offset_bottom = 0
	
	_create_ui()

func _create_ui():
	# Distance - top center (75% opacity)
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
	distance_label.anchor_bottom = 0
	distance_label.offset_left = -100
	distance_label.offset_right = 100
	distance_label.offset_top = 20
	distance_label.offset_bottom = 70
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
	coin_icon.add_theme_font_size_override("font_size", 36)
	coin_icon.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	coin_container.add_child(coin_icon)
	
	coin_label = Label.new()
	coin_label.text = " 0"
	if melon_font:
		coin_label.add_theme_font_override("font", melon_font)
	coin_label.add_theme_font_size_override("font_size", 28)
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
