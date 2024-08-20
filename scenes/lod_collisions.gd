extends StaticBody3D

@export var shapes: Array[Shape3D] = []

@onready var shape_node: CollisionShape3D = $CollisionShape3D

func _ready() -> void:
	if shapes.size() == 0:
		print("LOD Collision Shape has no shape!")
		return
	update_shape()
	Globals.add_scale_watcher(update_shape)

func update_shape() -> void:
	shape_node.shape = shapes[min(Globals.scale_index, shapes.size()-1)]
