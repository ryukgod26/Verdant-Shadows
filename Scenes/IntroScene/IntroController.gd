extends Node

# IntroController - manages the intro scene dialogue flow


func _ready():
	# Connect to dialogue end signal to know when intro is complete
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	
	# Start the intro dialogue
	var dialogue_resource = load("res://Scenes/IntroScene/intro.dialogue")
	DialogueManager.show_example_dialogue_balloon(dialogue_resource, "start")


func _on_dialogue_ended(_resource):
	# Dialogue has ended - the game can now begin
	# Add any post-intro logic here (e.g., enable player control, transition scenes)
	print("Intro dialogue completed!")
