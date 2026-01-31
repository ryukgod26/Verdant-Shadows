extends CanvasLayer


var music_vol_bus
var master_vol_bus
var sfx_vol_bus

func _ready() -> void:
	visible = false
	
	master_vol_bus = AudioServer.get_bus_index("Master")
	music_vol_bus = AudioServer.get_bus_index("Music")
	sfx_vol_bus = AudioServer.get_bus_index("SFX")


func _on_back_pressed() -> void:
	visible = false


func _on_master_vol_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(master_vol_bus,linear_to_db(value))
	AudioServer.set_bus_mute(master_vol_bus,value<.05)

func _on_music_vol_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(music_vol_bus,linear_to_db(value))
	AudioServer.set_bus_mute(master_vol_bus,value<.05)

func _on_sfx_vol_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(sfx_vol_bus,linear_to_db(value))
	AudioServer.set_bus_mute(master_vol_bus,value<.05)
