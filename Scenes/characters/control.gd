extends Control

@export var color: Color = Color.WHITE
@export var crosshair_size: int = 10
@export var thickness: int = 2

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)

func _draw():
	var center = Vector2.ZERO
	# Horizontal line
	draw_line(center + Vector2(-crosshair_size, 0), center + Vector2(crosshair_size, 0), color, thickness)
	# Vertical line
	draw_line(center + Vector2(0, -crosshair_size), center + Vector2(0, crosshair_size), color, thickness)
