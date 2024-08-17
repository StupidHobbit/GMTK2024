@tool
extends Interactable

const SHOW_DELAY: int = 10

@export var length: float = 1

@onready var shape: CapsuleShape3D = $CollisionShape3D.shape
@onready var mesh: CapsuleMesh = $MeshInstance3D.mesh

var last_hover: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	shape.height = length
	mesh.height = length
	$MeshInstance3D.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		# to apply visual changes in editor
		shape.height = length
		mesh.height = length
		
	else:
		if Time.get_ticks_msec() - last_hover > SHOW_DELAY:
			$MeshInstance3D.visible = false

func get_label() -> String:
	return "Climb"

func on_hover():
	last_hover = Time.get_ticks_msec()
	$MeshInstance3D.visible = true

func can_interact(player: Character) -> bool:
	var local_pos = to_local(player.position)
	if local_pos.y > 0:
		# player needs to be under ledge
		return false
	
	return true

func on_interact(player: Character):
	player.lc_start = player.position
	
	var dest: Vector3 = to_local(player.position)
	dest.y = position.y + 0.2
	dest.z = -1 * sign(dest.z) * 0.2
	dest.x = clamp(dest.x, -length/2, length/2)
	player.lc_dest = to_global(dest)
	
	player.ledge_climbing = true
