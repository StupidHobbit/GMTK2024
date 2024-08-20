@tool
extends Area3D
class_name LaunchPad

@onready var sound_player: AudioStreamPlayer3D = $SoundPlayer

@export var scale_: float = 1:
	set(new_value):
		scale = Vector3(new_value, new_value, new_value)
	get():
		return scale.x

@export var dir: Vector3 = Vector3.UP:
	set(new_value):
		dir = new_value
		var matrix = transform.inverse()
		var target = matrix * dir - matrix * Vector3.ZERO
		if is_node_ready():
			$VisualDir.target_position = target

@export_flags("Big:1", "Medium:2", "Small:4", "Smaller:8") var allowed_scales: int = 12

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		var matrix = global_transform.inverse()
		var target = matrix * dir - matrix * Vector3.ZERO
		if is_node_ready():
			$VisualDir.target_position = target

func can_launch(player: Character):
	var cur_scale: int = roundi(pow(2, Globals.scale_index))
	if (allowed_scales & cur_scale) == 0:
		return false
	
	return true

func play() -> void:
	play_anim()
	play_sound()

func play_anim() -> void:
	$GMTK24_Mesh_JumpPadAnim/AnimationPlayer.play("ArmatureAction")

func play_sound() -> void:
	sound_player.play()
