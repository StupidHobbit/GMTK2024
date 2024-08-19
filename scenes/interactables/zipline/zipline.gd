extends Node3D

class_name Zipline

const part_scene: PackedScene = preload("res://scenes/interactables/zipline/zipline_part.tscn")

@export var start_point: Node3D
@export var end_point: Node3D

@export var part_length: float = 0.5

var current_player: Character

func _ready() -> void:
	var current_pos = start_point.position
	var end_pos = end_point.position
	var zipline_length = (end_point.position - start_point.position).length()
	var direction = (end_pos - current_pos).normalized()
	for i in range(zipline_length / part_length + 1):
		var part: ZiplinePart = part_scene.instantiate()
		add_child(part)
		part.zipline = self
		part.position = current_pos
		part.look_at(end_pos)
		
		current_pos += direction * part_length

func start_player_travel(player: Character):
	current_player = player
	current_player.current_zipline = self

func stop_player_travel():
	current_player = null

func _process(delta: float) -> void:
	pass
