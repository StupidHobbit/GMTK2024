@tool
extends Area3D
class_name LaunchPad

@onready var shape: CylinderShape3D = $CollisionShape3D.shape
@onready var mesh: CylinderMesh = $MeshInstance3D.mesh

@export var radius: float = 0.2:
	set(new_value):
		radius = new_value
		if is_node_ready():
			shape.radius = radius
			mesh.bottom_radius = radius
			mesh.top_radius = radius

@export var height: float = 0.01:
	set(new_value):
		height = new_value
		if is_node_ready():
			shape.height = height
			mesh.height = height
			$CollisionShape3D.position.y = height/2
			$MeshInstance3D.position.y = height/2

@export var dir: Vector3 = Vector3.UP:
	set(new_value):
		dir = new_value
		if is_node_ready():
			$VisualDir.target_position = dir

func _ready() -> void:
	shape.radius = radius
	mesh.bottom_radius = radius
	mesh.top_radius = radius
	shape.height = height
	mesh.height = height
	$CollisionShape3D.position.y = height/2
	$MeshInstance3D.position.y = height/2
