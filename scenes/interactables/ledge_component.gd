@tool
extends Node3D

@export var length: float = 1
@export var enabled: bool = true

@onready var shape: CapsuleShape3D = $CollisionShape3D.shape
@onready var mesh: CapsuleMesh = $MeshInstance3D.mesh

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	shape.height = length
	mesh.height = length
	#$MeshInstance3D.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		# to apply visual changes in editor
		shape.height = length
		if mesh != null:
			mesh.height = length
		else:
			print("no mesh?")
		
	else:
		pass

func get_label() -> String:
	return "Press E to climb"

func can_interact(player: Character) -> bool:
	var local_pos = to_local(player.position)
	if local_pos > 0:
		# should be under ledge
		return false
	
	if -length/2 < local_pos.x < length/2:
		# should be in front of ledge
		return true
	
	return false

func on_interact(player: Character):
	print("interacting!")
	player.climbing_start = player.position
	
	var dest: Vector3 = to_local(player.position)
	dest.y = position.y
	dest.z = -1 * sign(dest.z) * 0.2
	player.climbing_dest = to_global(dest)
	
	player.climbing = true
	player.climb_step = 0
	# move player
	pass
