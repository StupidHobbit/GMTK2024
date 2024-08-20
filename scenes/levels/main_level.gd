extends Node3D

@export var player: Character
@export var level_start: CheckPoint

func _ready() -> void:
	Globals.scale_update.emit()

func end_level() -> void:
	if Globals.scale_index == Globals.SCALES.size()-1:
		end_game()
		return
	
	Globals.scale_down()
	player.position = level_start.position
	player.velocity = Vector3.ZERO
	player.current_zipline = null

func end_game() -> void:
	pass
