extends Button

var SCALE_ON_HOVER = 1.01

func _on_button_mouse_entered() -> void:
	pivot_offset = size/2
	var tween = create_tween()
	tween.tween_property(self,"scale",Vector2(SCALE_ON_HOVER, SCALE_ON_HOVER),0.1)


func _on_button_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(self,"scale",Vector2(1.0,1.0),0.1)
	
