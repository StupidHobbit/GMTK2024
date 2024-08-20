extends HBoxContainer

func _ready() -> void:
	var id = AudioServer.get_bus_index("SFX")
	var vol = AudioServer.get_bus_volume_db(id)
	$Sliders/SFXSlider.value = inverse_lerp(-25, 0, vol) * 100
	id = AudioServer.get_bus_index("BGM")
	vol = AudioServer.get_bus_volume_db(id)
	$Sliders/MusicSlider.value = inverse_lerp(-25, 0, vol) * 100

func on_music_slider_value_changed(value: float) -> void:
	var bgm_index= AudioServer.get_bus_index("BGM")
	if value == 0:
		AudioServer.set_bus_mute(bgm_index, true)
	else:
		AudioServer.set_bus_mute(bgm_index, false)
	AudioServer.set_bus_volume_db(bgm_index, lerpf(-25, 0, value / 100))

func on_sfx_slider_value_changed(value: float) -> void:
	var sfx_index= AudioServer.get_bus_index("SFX")
	if value == 0:
		AudioServer.set_bus_mute(sfx_index, true)
	else:
		AudioServer.set_bus_mute(sfx_index, false)
	AudioServer.set_bus_volume_db(sfx_index, lerpf(-25, 0, value/100))
