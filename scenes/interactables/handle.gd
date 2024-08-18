@tool
extends Marker3D

var prev_pos: Vector3 = position

signal moved()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		if prev_pos != position:
			prev_pos = position
			moved.emit()
