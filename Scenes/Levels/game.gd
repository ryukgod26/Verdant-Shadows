extends Node3D

var dialogue_resource = preload("res://Scenes/IntroScene/intro.dialogue")

func _ready() -> void:
	# Show intro dialogue when game starts
	show_intro_dialogue()


func show_intro_dialogue() -> void:
	DialogueManager.show_example_dialogue_balloon(dialogue_resource, "start")


func _process(_delta: float) -> void:
	pass
