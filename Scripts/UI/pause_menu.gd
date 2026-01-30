extends CanvasLayer

var paused: bool:
	set(val):
		get_tree().paused = val
		visible = val
		paused = val

func _ready() -> void:
	visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Pause"):
		paused = not paused

func _on_resume_pressed() -> void:
	paused = not paused

func _on_options_pressed() -> void:
	$Options.visible = true

func _on_main_menu_pressed() -> void:
	paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/main_menu.tscn")
