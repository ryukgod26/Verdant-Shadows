extends CanvasLayer

signal resumed
signal quit_to_menu

var _is_paused := false
var _hud: Control

@onready var _coins_label: Label = %CoinsLabel
@onready var _distance_label: Label = %DistanceLabel

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Pause"):
		if _is_paused:
			_resume()
		else:
			_pause()
		get_viewport().set_input_as_handled()


func _pause() -> void:
	_is_paused = true
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	_find_and_hide_hud()
	_update_stats()


func _resume() -> void:
	_is_paused = false
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if _hud:
		_hud.visible = true
	
	resumed.emit()


func _find_and_hide_hud() -> void:
	if not _hud:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			# HUD might be moved to HUDLayer by player script
			var hud_layer = player.get_node_or_null("HUDLayer")
			if hud_layer:
				_hud = hud_layer.get_node_or_null("HUD")
			if not _hud:
				_hud = player.get_node_or_null("HUD")
	
	if _hud:
		_hud.visible = false


func _update_stats() -> void:
	if _hud:
		if _coins_label:
			_coins_label.text = str(_hud.coin_count)
		if _distance_label:
			_distance_label.text = str(int(_hud.distance_meters)) + " m"
	else:
		if _coins_label:
			_coins_label.text = "0"
		if _distance_label:
			_distance_label.text = "0 m"


func _on_resume_pressed() -> void:
	_resume()


func _on_quit_pressed() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	quit_to_menu.emit()
	get_tree().change_scene_to_file("res://Scenes/UI/main_menu.tscn")
