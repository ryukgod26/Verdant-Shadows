extends Node3D

@export var min_blink_time := 1.
@export var max_blink_time := 3.

var rng = RandomNumberGenerator.new()

func _on_timer_timeout() -> void:
	$OmniLight3D.visible = not $OmniLight3D.visible
	$Timer.wait_time = rng.randf_range(min_blink_time,max_blink_time)
