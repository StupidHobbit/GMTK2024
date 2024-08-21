extends Node3D

var LOD_shapes: Array[Node] = []

@onready var shape_node: Node3D = $CurrentShape

func _ready() -> void:
	if get_child_count() == 0:
		print("LOD Collision Shape has no children!")
		return
	
	for child in get_children():
		if child == shape_node: continue
		LOD_shapes.append(child)
		remove_child(child)
	
	update_shape()
	Globals.add_scale_watcher(update_shape)

func update_shape() -> void:
	var id: int = Globals.scale_index
	
	for child in shape_node.get_children():
		shape_node.remove_child(child)
	
	if id >= LOD_shapes.size():
		return
	
	shape_node.add_child(LOD_shapes[id])
