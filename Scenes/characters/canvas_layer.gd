extends Control

var runes_collected = [false, false, false, false, false]

func _ready():
	update_runes()

func update_runes():
	queue_redraw()

func collect_rune(index: int):
	runes_collected[index] = true
	update_runes()

func _draw():
	var start_pos = Vector2(20, 20)
	var spacing = 30
	var radius = 10
	
	for i in range(5):
		var pos = start_pos + Vector2(i * spacing, 0)
		var col = Color(0.2, 0.5, 1.0) if runes_collected[i] else Color(0.1, 0.15, 0.25)
		draw_circle(pos, radius, col)
