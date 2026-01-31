extends CanvasLayer

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Levels/game.tscn")


func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/UI/options.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit(0)
