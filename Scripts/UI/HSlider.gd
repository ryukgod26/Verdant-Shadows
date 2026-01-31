extends HSlider

@export var show_on_hover_only: bool = true
@onready var label


@export var vertical_offset: float = 5.0 

func _ready():
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text = str(value)
	label.add_theme_color_override("font_color", Color.WHITE) 
	

	add_child(label)
	
	if show_on_hover_only:
		label.modulate.a = 0.0 
	

	value_changed.connect(_on_value_changed)
	drag_started.connect(_on_drag_started)
	drag_ended.connect(_on_drag_ended)
	
	update_label_position()


func _on_value_changed(new_value):
	update_label_position()
	label.text = str(new_value)

func update_label_position():
	var grabber_icon = get_theme_icon("grabber")
	var grabber_width = grabber_icon.get_width()
	
	var ratioH = 0.0
	if max_value > min_value:
		ratioH = (value - min_value) / (max_value - min_value)
	
	var available_width = size.x - grabber_width
	var grabber_x = (ratioH * available_width) + (grabber_width / 2.0)
	
	label.position.x = grabber_x - (label.size.x / 2.0)
	label.position.y = -label.size.y - vertical_offset


func _on_drag_started() -> void:
	if show_on_hover_only:
		var tween = create_tween()
		tween.tween_property(label, "modulate:a", 1.0, 0.2)

func _on_drag_ended(_value_changed: bool) -> void:
	if show_on_hover_only:
		var tween = create_tween()
		tween.tween_property(label, "modulate:a", 0.0, 0.2)
