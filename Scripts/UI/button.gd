extends Button

const ANIMATION_DURATION := 0.12
const GLOW_COLOR := Color(0.4, 0.8, 0.5, 0.6)

var _tween: Tween
var _original_modulate: Color

func _ready() -> void:
	_original_modulate = modulate


func _on_button_mouse_entered() -> void:
	_kill_active_tween()
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_tween.tween_property(self, "modulate", Color(1.3, 1.4, 1.3, 1.0), ANIMATION_DURATION)


func _on_button_mouse_exited() -> void:
	_kill_active_tween()
	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_tween.tween_property(self, "modulate", _original_modulate, ANIMATION_DURATION)


func _kill_active_tween() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	
