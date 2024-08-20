extends Node

@onready var main_menu: AudioStreamPlayer = $main_menu
@onready var level_1: AudioStreamPlayer = $level1
@onready var level_2: AudioStreamPlayer = $level2
@onready var level_3: AudioStreamPlayer = $level3

var all_streams: Array[AudioStreamPlayer]

func play_stream(stream_to_play: AudioStreamPlayer):
	for stream in all_streams:
		if stream != stream_to_play:
			stream.stop()
	stream_to_play.play()

func start_menu_music():
	play_stream(main_menu)

func _ready() -> void:
	all_streams = [
		main_menu,
		level_1,
		level_2,
		level_3,
	]
	start_menu_music()
	Globals.add_scale_watcher(update_music)
	
func update_music():
	var scale = Globals.scale
	if scale > 1:
		play_stream(level_1)
	elif scale > 0.4:
		play_stream(level_2)
	else:
		play_stream(level_3)
