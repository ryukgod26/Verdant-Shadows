extends Button



func _on_button_mouse_entered() -> void:
	pivot_offset = size/2
	var tween = create_tween()
	tween.tween_property(self,"scale",Vector2(1.2,1.2),0.2)


func _on_button_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(self,"scale",Vector2(1.,1.),0.2)
	
