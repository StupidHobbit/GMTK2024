extends CanvasLayer

@onready var pause := self
@onready var resume_option := $MarginContainer/Control/VBoxOptions/Resume
@onready var label = $MarginContainer/Control/Label
@onready var pause_options = $MarginContainer/Control/VBoxOptions
@onready var color_rect = $ColorRect
@onready var audio_sliders = $MarginContainer/Control/AudioSliders

@onready var nodes_grp1 = [label] # should be visible during gamemplay and hidden during pause
@onready var nodes_grp2 = [pause_options, color_rect, audio_sliders] # should be visible only in pause menu

@export var player: Character

func _ready():
	pause_hide()

func pause_show():
	for n in nodes_grp1:
		n.hide()
	for n in nodes_grp2:
		n.show()
	if player != null:
		player.stop_handle_input()

func pause_hide():
	for n in nodes_grp2:
		if n:
			n.hide()
	if player != null:
		player.start_handle_input()

func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			resume()
		else:
			pause_game()
		get_viewport().set_input_as_handled()

func resume():
	get_tree().paused = false
	pause_hide()

func pause_game():
	resume_option.grab_focus()
	get_tree().paused = true
	pause_show()

func _on_Resume_pressed():
	resume()

func _on_main_menu_pressed():
	Game.change_scene_to_file("res://scenes/menu/menu.tscn", {"show_progress_bar": false})
	MusicPlayer.start_menu_music()
