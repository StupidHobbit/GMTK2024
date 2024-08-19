@tool
extends Interactable

const SHOW_DELAY: int = 10

@onready var shape: CapsuleShape3D = $CollisionShape3D.shape
@onready var mesh: CapsuleMesh = $MeshInstance3D.mesh

@onready var handle1: Marker3D = $Handles/Handle1
@onready var handle2: Marker3D = $Handles/Handle2

@export var length: float = 1:
	set(new_value):
		length = new_value
		if is_node_ready():
			shape.height = length
			mesh.height = length

@export_flags("Big:1", "Medium:2", "Small:4", "Smaller:8") var allowed_scales: int = 31

var last_hover: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	shape.height = length
	mesh.height = length
	
	if not Engine.is_editor_hint():
		$MeshInstance3D.visible = false
		Globals.add_scale_watcher(on_scale_update)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		if Time.get_ticks_msec() - last_hover > SHOW_DELAY:
			$MeshInstance3D.visible = false

func on_scale_update():
	shape.radius = min(0.3 * Globals.scale, length/2)
	mesh.radius = min(0.02 * Globals.scale, length/2)

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
	
	var cur_scale: int = pow(2, player.scale_index)
	if (allowed_scales & cur_scale) == 0:
		return false
	
	return true

func on_interact(player: Character):
	player.lc_start = player.position
	
	var dest: Vector3 = to_local(player.position)
	dest.y = 0
	dest.z = -1 * sign(dest.z) * 0.3 * Globals.scale
	dest.x = clamp(dest.x, -length/2, length/2)
	player.lc_dest = to_global(dest)
	
	player.ledge_climbing = true

func on_marker_move() -> void:
	var pos1 = handle1.position
	var pos2 = handle2.position
	
	var center = (pos1 + pos2) / 2
	var dir = Vector3.UP.cross(pos1 - pos2)
	var up = -dir.cross(pos1 - pos2)
	
	if dir.is_equal_approx(Vector3.ZERO) or \
		up.is_equal_approx(Vector3.ZERO) or \
		up.cross(dir).is_equal_approx(Vector3.ZERO) :
		print("points too close together, skipping update")
		return
	
	self.look_at_from_position(center, center + dir, up)
	length = (pos1 - pos2).length()
