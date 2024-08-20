extends Node3D

@export var player: Character
@export var level_starts: Array[CheckPoint]

func _ready() -> void:
	Globals.scale_update.emit()
	MusicPlayer.update_music()

func end_level() -> void:
	if Globals.scale_index == Globals.SCALES.size()-1:
		end_game()
		return
	
	Globals.scale_down()
	player.reset(level_starts[Globals.scale_index])

func end_game() -> void:
	pass

func on_checkpoint_activated(cp: CheckPoint) -> void:
	player.current_checkpoint = cp
