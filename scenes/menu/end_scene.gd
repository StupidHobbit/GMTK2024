extends Control

func _ready() -> void:
	$Timer.start()

func _on_animated_sprite_2d_animation_finished() -> void:
	Game.change_scene_to_file("res://scenes/menu/menu.tscn", {"show_progress_bar": false})
	MusicPlayer.start_menu_music()
