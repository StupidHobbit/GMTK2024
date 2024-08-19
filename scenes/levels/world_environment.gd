extends WorldEnvironment

func _ready():
	environment.adjustment_enabled = true
	update_post_processing()
	Globals.add_scale_watcher(update_post_processing)

func update_post_processing():
	var scale = Globals.scale
	if scale > 1:
		environment.adjustment_saturation = 0.4
		environment.adjustment_contrast = 0.6
		environment.adjustment_brightness = 0.6
	elif scale > 0.4:
		environment.adjustment_saturation = 0.8
		environment.adjustment_contrast = 0.8
		environment.adjustment_brightness = 0.8
	else:
		environment.adjustment_saturation = 1
		environment.adjustment_contrast = 1
		environment.adjustment_brightness = 1
